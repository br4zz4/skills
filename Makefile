.PHONY: validate test

validate:
	@bash scripts/validate.sh .

test:
	@bash test/validate_test.sh
