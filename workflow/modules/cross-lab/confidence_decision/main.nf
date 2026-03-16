process CONFIDENCE_DECISION {
    tag "$sample_id"
    container "$projectDir/containers/samtools.sif"
    publishDir "${params.outdir ?: 'results'}/confidence_decision", mode: 'copy'

    input:
    tuple val(sample_id), path(in_bam)

    output:
    tuple val(sample_id), path("targeted_references.txt"), path(in_bam), emit: confidence_result

    script:
    """
    samtools index ${in_bam}
    echo "Getting list of genomes from BAM"

    TARGET_LIST="Targets that Will Be Remapped"
    touch targeted_references.txt
    samtools idxstats ${in_bam} | awk '{print \$1}' | head -n -1 | while read ref; do
        echo "Processing reference: \$ref"

        COVERAGE=\$(samtools depth -a -r \$ref ${in_bam} | \
        awk '{total++; if(\$3>=5) covered++} END {if(total>0) print (covered/total)*100 "%"; else print "0%"}')

        COVERAGE_INT="\$(echo \$COVERAGE | tr -d '%' | cut -d. -f1)"

        echo "Coverage(>5x): \$COVERAGE"

        MEAN_DEPTH=\$(samtools depth -a -r \$ref ${in_bam} | awk '{sum+=\$3; count++} END {if(count>0) print sum/count; else print 0}')
        
        MEAN_DEPTH_INT="\${MEAN_DEPTH%%.*}"  # remove decimal part

        echo "Mean depth: \$MEAN_DEPTH bases"

        if [[ \$COVERAGE_INT -ge 55 && \$MEAN_DEPTH_INT -ge 15 ]]; then
            echo ""
            echo "Will be added"
            echo ""
            TARGET_LIST+=\$'\n'\$ref
            echo \$ref >> targeted_references.txt
        else
            echo ""
            echo "Under threshold. Will NOT be added."
            echo ""
        fi

    done
    """
}

