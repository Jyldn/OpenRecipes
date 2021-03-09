all:sbcl-check quicklisp-check recipes

all-recipes:
	@sbcl --noinform --load openrecipes.lisp

sbcl-check:
ifeq (, $(shell which sbcl 2>/dev/null))
$(error "No sbcl in your current PATH variable, Please install sbcl from your package manager or compile it from their github releases.")
endif

quicklisp-check:
ifeq ("$(shell echo $(shell sbcl --noinform --eval "(print (find-package \"QUICKLISP\"))" --eval "(sb-ext:exit)" | tail -n1))", "NIL")
	@echo "Installing Quicklisp.."
	@curl "https://beta.quicklisp.org/quicklisp.lisp" > /tmp/quicklisp.lisp
	@sbcl --load /tmp/quicklisp.lisp --eval "(quicklisp-quickstart:install :path \"~/.local/share/ql\")" --eval "(ql:add-to-init-file)" --eval "(sb-ext:exit)"
endif
ifeq (install,$(filter install,$(MAKECMDGOALS)))
.PHONY: quicklisp-check sbcl-check clean 
endif
