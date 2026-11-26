# workflow/rules/multiqc.smk
# Aggregate QC reports (from fastp and/or FastQC) into a single report.

rule multiqc:
    input:
        get_multiqc_input
    output:
        html=f"{get_step_dir('multiqc')}/multiqc_report.html"
    conda:
        "../envs/multiqc_env.yaml"
    log:
        "logs/multiqc/multiqc.log"
    params:
        qc_dirs=lambda wildcards: " ".join(get_multiqc_dirs())
    shell:
        """
        multiqc {params.qc_dirs} \
            --outdir {get_step_dir('multiqc')} \
            --filename multiqc_report.html \
            > {log} 2>&1
        """
