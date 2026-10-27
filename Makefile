# Build the pinned grammar into this plugin's runtimepath: the shared
# parser plus the editor queries, both taken from the same tag so the
# plugin never drifts from its grammar.

GRAMMAR_URL ?= https://github.com/derivasoftware/tree-sitter-plantuml.git
GRAMMAR_TAG ?= v0.16.0
BUILD := build/tree-sitter-plantuml

all: parser/plantuml.so queries/plantuml/highlights.scm

$(BUILD):
	git clone --depth 1 --branch $(GRAMMAR_TAG) $(GRAMMAR_URL) $(BUILD)

parser/plantuml.so: $(BUILD)
	mkdir -p parser
	cc -shared -fPIC -O2 -I$(BUILD)/src \
	  $(BUILD)/src/parser.c $(BUILD)/src/scanner.c -o $@

queries/plantuml/highlights.scm: $(BUILD)
	mkdir -p queries/plantuml
	cp $(BUILD)/queries/*.scm queries/plantuml/

clean:
	rm -rf build parser queries/plantuml

.PHONY: all clean
