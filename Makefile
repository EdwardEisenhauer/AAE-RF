BUILD_DIR = `pwd`/build
OUT_DIR   = `pwd`/out

DOCKER_IMAGE = latex-builder
LATEX_OPTIONS = -xelatex
#  -interaction=nonstopmode
PACKAGE_NAME = WUSTReport

SOURCE_DIRS = $(shell ls -d */ | grep -v "^build")
SOURCE_TEXS = $(SOURCE_DIRS:=Report/main.tex)
PDFBUILDS = $(addprefix $(BUILD_DIR)/, $(SOURCE_DIRS:/=.pdf))


.DEFAULT_GOAL := all


clean :
	-rm -r $(BUILD_DIR) $(OUT_DIR) $(PACKAGE_NAME).sty
.PHONY : clean


all : $(PDFBUILDS)
.PHONY : all


sty : $(PACKAGE_NAME).sty
.PHONY : sty
$(PACKAGE_NAME).sty : $(PACKAGE_NAME).ins $(PACKAGE_NAME).dtx
	mkdir -p $(BUILD_DIR)
	yes | latex -output-directory=$(BUILD_DIR) $(PACKAGE_NAME).ins
	cp $(BUILD_DIR)/$@ $@


$(PDFBUILDS) : $(BUILD_DIR)/%.pdf: $(PACKAGE_NAME).sty %/Report/main.tex
	mkdir -p $(BUILD_DIR) $(OUT_DIR)
	cp logo-pwr-2016.pdf $(BUILD_DIR)/
	latexmk $(LATEX_OPTIONS) \
		-cd \
		-jobname=$* \
		-output-directory=$(BUILD_DIR) \
		$*/Report/main
	cp $(BUILD_DIR)/$*.pdf $(OUT_DIR)/$*.pdf

hadolint : Dockerfile
	docker run --rm --interactive hadolint/hadolint < Dockerfile
.PHONY : hadolint


image : Dockerfile
	docker build \
		--tag $(DOCKER_IMAGE) \
		.
.PHONY : image


docker : image ## Compile the project via the latex-builder docker image
	docker run \
		--rm \
		--interactive \
		--workdir /data \
		--volume `pwd`:/data \
		--name=$(DOCKER_IMAGE) \
		$(DOCKER_IMAGE) \
		sh -c "make all"
.PHONY : docker
