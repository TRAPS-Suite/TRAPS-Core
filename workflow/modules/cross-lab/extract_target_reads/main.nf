process EXTRACT_TARGET_READS {
    tag "$sample_id"
    container "$projectDir/containers/samtools.sif"
    publishDir "${params.outdir ?: 'results'}/extract_viral_reads", mode: 'copy'

    input:
    tuple val(sample_id), path(bam_file)

    output:
    tuple val(sample_id), path("_extracted_bases.bam"), emit: extracted

    script:
    """
    touch refs2.txt
    touch refs.txt
    samtools idxstats "${bam_file}" \
    | awk 'NR > 1 && \$1 != "*" { print \$1 }' "${bam_file}.idxstats" > refs2.txt

    sed '1d' refs2.txt > refs.txt
    samtools index ${bam_file}
    while IFS= read -r line; do
    echo "Processing line: \$line"
    samtools view -b ${bam_file} \$line > "\${line}_extracted_bases.bam"
    done < refs.txt
    """
}
