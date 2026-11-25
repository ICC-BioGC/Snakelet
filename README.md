├── .gitignore
├── README.md
├── LICENSE.md
├── workflow
│   ├── rules
│   │   ├── basespace.smk
│   │   ├── fastqc.smk
│   │   ├── spades.smk
│   │   └── ... (um arquivo .smk por etapa)
│   ├── envs
│   │   ├── fastqc.yaml
│   │   ├── spades.yaml
│   │   └── ... (um YAML por ferramenta)
│   ├── scripts
│   │   └── ... (scripts Python/R auxiliares)
│   ├── profiles
│   │   └── default
│   │       └── config.yaml
│   └── Snakefile
├── config
│   ├── config.yaml
│   └── samples.tsv
├── resources
└── results
