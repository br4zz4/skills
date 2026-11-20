.PHONY: validate test

validate:
	@bash scripts/validate.sh .

test:
	@bash test/validate_test.sh

.PHONY: hooks
hooks:
	@git config core.hooksPath scripts/git-hooks
	@echo "hooks enabled: scripts/git-hooks"
