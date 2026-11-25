```
.
├── .gitignore
├── README.md
├── LICENSE.md
├── workflow
│   ├── Snakefile
│   ├── rules
│   │   ├── common.smk
│   │   ├── basespace.smk
│   │   ├── fastqc.smk
│   │   ├── spades.smk
│   │   ├── quast.smk
│   │   ├── checkm.smk
│   │   ├── prokka.smk
│   │   ├── mlst.smk
│   │   ├── rgi.smk
│   │   ├── kraken2.smk
│   │   ├── bracken.smk
│   │   ├── abricate.smk
│   │   ├── eggnog.smk
│   │   └── fastani.smk
│   ├── envs
│   │   ├── fastqc.yaml
│   │   ├── spades.yaml
│   │   ├── quast.yaml
│   │   ├── checkm.yaml
│   │   ├── prokka.yaml
│   │   ├── mlst.yaml
│   │   ├── rgi.yaml
│   │   ├── kraken2.yaml
│   │   ├── bracken.yaml
│   │   ├── abricate.yaml
│   │   ├── eggnog.yaml
│   │   ├── fastani.yaml
│   │   └── multiqc.yaml
│   ├── scripts
│   │   └── (place any custom Python/R helper scripts here)
│   └── profiles
│       ├── default
│       │   └── config.yaml
│       └── slurm
│           └── config.yaml
├── config
│   ├── config.yaml
│   └── samples.tsv
├── resources
│   └── (reference genomes, databases, etc.)
└── results
    └── (all workflow output goes here)
```
