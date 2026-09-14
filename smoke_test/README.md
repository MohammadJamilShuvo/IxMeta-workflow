# Functional smoke test

The smoke test generates deterministic synthetic paired-end reads from a synthetic host sequence and two synthetic microbial sequences. It verifies rule connectivity and host depletion without requiring external data.

```bash
python smoke_test/make_smoke_data.py
python scripts/check_inputs.py --config smoke_test/config.yaml
snakemake -s workflow/Snakefile --configfile smoke_test/config.yaml --use-conda --cores 4 --printshellcmds
```

The test is intentionally small and does not validate taxonomic/diagnostic accuracy.
