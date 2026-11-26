# workflow/rules/common.smk

def get_qc_fastq_input(wildcards):
    """
    Return the FASTQ files to be used by FastQC.
    - Mode "full" or "fastp": use fastp-trimmed reads.
    - Mode "fastqc": use raw reads.
    """
    mode = config["qc"]["mode"]
    if mode in ("full", "fastp"):
        return [
            f"{get_step_dir('fastp')}/{wildcards.sample}_R1.fastq.gz",
            f"{get_step_dir('fastp')}/{wildcards.sample}_R2.fastq.gz",
        ]
    elif mode == "fastqc":
        return get_fastq(wildcards)
    else:
        raise ValueError(f"Unknown qc.mode: {mode}")


def get_multiqc_dirs():
    """
    Return the list of directories that MultiQC should scan.
    Depends on which QC tools were run.
    """
    mode = config["qc"]["mode"]
    dirs = []
    if mode in ("full", "fastp"):
        dirs.append(get_step_dir("fastp"))
    if mode in ("full", "fastqc"):
        dirs.append(get_step_dir("fastqc"))
    return dirs


def get_multiqc_input(wildcards):
    """
    Return the QC report files that MultiQC depends on.
    This ensures fastp and/or FastQC run before MultiQC.
    """
    mode = config["qc"]["mode"]
    inputs = []
    if mode in ("full", "fastp"):
        inputs.extend(expand(f"{get_step_dir('fastp')}/{{sample}}.html", sample=SAMPLES))
        inputs.extend(expand(f"{get_step_dir('fastp')}/{{sample}}.json", sample=SAMPLES))
    if mode in ("full", "fastqc"):
        inputs.extend(expand(f"{get_step_dir('fastqc')}/{{sample}}_fastqc.html", sample=SAMPLES))
        inputs.extend(expand(f"{get_step_dir('fastqc')}/{{sample}}_fastqc.zip", sample=SAMPLES))
    return inputs
