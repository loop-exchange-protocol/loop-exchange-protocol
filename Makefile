.PHONY: schema-check yaml-check shell-check docs-check svg-check stale-check ci

schema-check:
	@find schemas -type f -name '*.schema.json' -exec python3 -m json.tool {} \; >/dev/null
	@python3 scripts/check_schemas.py

yaml-check:
	@python3 -c 'import sys,yaml; [yaml.safe_load(open(p, encoding="utf-8")) for p in sys.argv[1:]]' $$(find examples -type f \( -name '*.yaml' -o -name '*.yml' \))

shell-check:
	@find examples -type f -name '*.sh' -exec bash -n {} \;

docs-check:
	@python3 scripts/check_docs.py

svg-check:
	@python3 -c 'import sys,xml.etree.ElementTree as E; [E.parse(p) for p in sys.argv[1:]]' $$(find assets -type f -name '*.svg')

stale-check:
	@! grep -R -EIn --exclude='*.html' --exclude-dir='.git' 'github\.com/mobai|dark2momo|lxp-open|publish command|runtime bindings?|scripts/verify-local\.sh|go test \./\.\.\.|go vet \./\.\.\.' README*.md AGENTS*.md CONTRIBUTING*.md docs examples schemas .github

ci: schema-check yaml-check shell-check docs-check svg-check stale-check
	@git diff --check
