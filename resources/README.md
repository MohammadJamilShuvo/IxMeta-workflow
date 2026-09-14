# External resources

Large references/databases are not version-controlled.

Expected locations after setup:

```text
resources/
├── ixodes_ricinus/
│   └── GCA_964199275.3.fna
├── kraken2/
│   └── <database>/
└── candidates/
    ├── candidate_reference.fa
    └── comparative_references.fa
```

Use `scripts/fetch_ixodes_reference.sh` to retrieve the host genome. Kraken2 and candidate resources are configured explicitly in the run YAML.
