process BWAMEM2_INDEX {
    tag "${ref_name}"
    publishDir "${params.outdir}/bwamem2_indexes", mode: 'copy'

    input:
    tuple val(ref_name), path(ref_path), val(prefix)

    output:
    tuple val(ref_name),
          path("*.amb"),
          path("*.ann"),
          path("*.pac"),
          path("*.0123"),
          path("*.bwt.2bit.64"),
          path(ref_path),
          emit: index_bundle

    script:
    def formatted_name = "${ref_name.replaceAll(' ', '_')}_index".toLowerCase()
    """
    echo "Started indexing pathogen reference ${ref_name.replaceAll(' ', '_').toLowerCase()}"

    bwa-mem2 index -p ${formatted_name} ${ref_path}
    """
}


process BWAMEM2 {
    tag "${sample_id}-${reference_name.replaceAll(' ', '_').toLowerCase()}"
    container "\$projectDir/containers/bwa-mem2.sif"
    publishDir "${params.outdir}/bwamem2", mode: 'copy'

    input:
    tuple val(sample_id),
          path(read_1),
          path(read_2),
          path(fastp_json_report),
          path(fastp_html_report),
          val(reference_name),
          path(ref_amb),
          path(ref_ann),
          path(ref_pac),
          path(ref_0123),
          path(ref_bwt_2bit_64),
          path(ref_fasta),
          path(ref_fasta_fai),
          path(ref_dict)
    val(single_end)
    
    output:
    tuple val(sample_id),
        path("${sample_id}-${reference_name.replaceAll(' ', '_').toLowerCase()}.sorted.bam"),
        path("${sample_id}-${reference_name.replaceAll(' ', '_').toLowerCase()}.sorted.bam.bai"),
        path(ref_fasta),
        path(ref_fasta_fai),
        path(ref_dict),
        val("${sample_id}-${reference_name.replaceAll(' ', '_').toLowerCase()}"),
        emit: aligned_sorted

    script:
    // Define these HERE — visible to both output: and script:
    def formatted_ref_name   = "${reference_name.replaceAll(' ', '_')}".toLowerCase()
    def formatted_index_name = "${reference_name.replaceAll(' ', '_')}_index".toLowerCase()
    def sxr_prefix           = "${sample_id}-${formatted_ref_name}"
    if (single_end)
        """
        echo "Started single-end alignment of sample ${sample_id}, reference ${formatted_ref_name}"

        bwa-mem2 mem \
            -t ${task.cpus} \
            -R "@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA" \
            ${formatted_index_name} \
            ${read_1} \
        | samtools sort \
            -@ ${task.cpus} \
            -m 2G \
            -o ${sxr_prefix}.sorted.bam

        samtools index \
            -@ ${task.cpus} \
            ${sxr_prefix}.sorted.bam
        """
    else
        """
        echo "Started paired-end alignment of sample ${sample_id}, reference ${formatted_ref_name}"

        bwa-mem2 mem \
            -t ${task.cpus} \
            -R "@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA" \
            ${formatted_index_name} \
            ${read_1} \
            ${read_2} \
        | samtools sort \
            -@ ${task.cpus} \
            -m 2G \
            -o ${sxr_prefix}.sorted.bam

        samtools index \
            -@ ${task.cpus} \
            ${sxr_prefix}.sorted.bam
        """
}