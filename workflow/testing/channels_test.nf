workflow {
fastq_pairs_ch = Channel.fromPath(
    '/work/crosslab/hsommer/ots_data/*_R{1,2}_001.fastq.gz',
    checkIfExists: true,
) .map { file ->

        def sample_id = file.name.replaceFirst(/_R[12]_001\.fastq\.gz$/, '')

        def meta = [sample_id]

        tuple(meta, file)
    }
    fastq_pairs_ch.view()
}