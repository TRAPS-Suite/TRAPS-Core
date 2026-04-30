process get_cores {
    publishDir "${params.outdir ?: 'results'}/stats", mode: 'copy'
    output:
    stdout emit: cores_chanel

    // Script to execute within the process
    script:
    """
    nproc --all
    """
}

process get_ram {
    publishDir "${params.outdir ?: 'results'}/stats", mode: 'copy'
    output:
    stdout emit: ram_channel

    script:
    """
    grep MemTotal /proc/meminfo | awk '{print int(\$2/1024/1024)}'
    """

}

// Define the main workflow
workflow {
    // Call the 'create_greeting' process with the 'params.greeting' value
    get_cores()
    get_cores.out.cores_chanel.view { "Cores Available: $it" }

    get_ram()
    get_ram.out.ram_channel.view {"Ram Available (GB): $it"}
}