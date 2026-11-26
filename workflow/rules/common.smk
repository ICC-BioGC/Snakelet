# workflow/rules/common.smk
import glob
import os

def discover_samples_from_dir(wildcards=None):
    """
    Recursively search the configured input directory for FASTQ files
    and extract sample names from them.
    
    The input directory is read from config["input_fastq_dir"].
    This function is evaluated at DAG-building time.
    """
    input_dir = config["input_fastq_dir"]
    
    # Define o padrão de busca. Ajuste conforme a nomenclatura dos seus arquivos.
    # Exemplo: busca por arquivos terminados em _R1.fastq.gz ou _R2.fastq.gz
    # O padrão '**' com recursive=True faz a busca em subpastas.
    pattern = os.path.join(input_dir, "**", "*_R{1,2}.fastq.gz")
    
    # Busca todos os arquivos que correspondem ao padrão
    fastq_files = glob.glob(pattern, recursive=True)
    
    # Extrai o nome da amostra de cada caminho de arquivo.
    # A lógica de extração depende da nomenclatura dos seus arquivos.
    # Exemplo: se o arquivo é /path/to/sampleA_R1.fastq.gz, a amostra é "sampleA".
    samples = set()
    for fq in fastq_files:
        basename = os.path.basename(fq)
        # Remove o sufixo _R1.fastq.gz ou _R2.fastq.gz para obter o nome da amostra
        sample_name = basename.replace("_R1.fastq.gz", "").replace("_R2.fastq.gz", "")
        if sample_name:
            samples.add(sample_name)
    
    return sorted(list(samples))
