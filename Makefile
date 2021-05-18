# Makefile for Sphinx documentation

# You can set these variables from the command line.
SPHINXBUILD   = sphinx-build
SOURCEDIR     = source
BUILDDIR      = build
SPHINXOPTS    =

.PHONY: help clean html changes linkcheck

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  clean     to remove the build directory"
	@echo "  html      to make standalone HTML files"
	@echo "  changes   to make an overview of all changed/added/deprecated items"
	@echo "  linkcheck to check all external links for integrity"

clean:
	-rm -rf $(BUILDDIR)/*

html: $(SOURCEDIR)
	pwd
	ls
	$(SPHINXBUILD) -W -b html $(SPHINXOPTS) $(SOURCEDIR) $(BUILDDIR)/html

changes: $(SOURCEDIR)
	$(SPHINXBUILD) -b changes $(SPHINXOPTS) $(SOURCEDIR) $(BUILDDIR)/changes

linkcheck: $(SOURCEDIR)
	# Occasionally this will fail with a 403 error on links that work in your browser
	# So far it's been enough to replace them with an alternate link to the same paper
	# If it continues to be a problem, configuring the user-agent may help:
	# https://github.com/sphinx-doc/sphinx/issues/7369
	$(SPHINXBUILD) -b linkcheck $(SPHINXOPTS) $(SOURCEDIR) $(BUILDDIR)/linkcheck
	@echo
	@echo "Link check complete; look for any errors in the above output " \
	      "or in $(BUILDDIR)/linkcheck/output.txt."

GIT_SAMPLE_DATA_REPO        := https://bitbucket.org/natcap/invest-sample-data.git
GIT_SAMPLE_DATA_REPO_PATH   := invest-sample-data
GIT_SAMPLE_DATA_REPO_REV    := b7a51f189315e08484b5ba997a5c1de88ab7f06d
sampledata:
	-git clone $(GIT_SAMPLE_DATA_REPO) $(GIT_SAMPLE_DATA_REPO_PATH)
	git -C $(GIT_SAMPLE_DATA_REPO_PATH) fetch
	git -C $(GIT_SAMPLE_DATA_REPO_PATH) lfs install
	git -C $(GIT_SAMPLE_DATA_REPO_PATH) lfs fetch
	git -C $(GIT_SAMPLE_DATA_REPO_PATH) checkout $(GIT_SAMPLE_DATA_REPO_REV)

	# modifications to certain sample data files so they display nicely
	# single backslashes don't get rendered in the csv-table, replace with double backslashes
	sed 's/\\/\\\\/g' invest-sample-data/HabitatRiskAssess/Input/habitat_stressor_info.csv > invest-sample-data/HabitatRiskAssess/Input/habitat_stressor_info_modified.csv

	# selections of tables that are too long to display in full
	head -n1 invest-sample-data/pollination/landcover_biophysical_table.csv > invest-sample-data/pollination/landcover_biophysical_table_modified.csv
	tail -n3 invest-sample-data/pollination/landcover_biophysical_table.csv >> invest-sample-data/pollination/landcover_biophysical_table_modified.csv

	head -n2 invest-sample-data/Carbon/carbon_pools_willamette.csv > invest-sample-data/Carbon/carbon_pools_willamette_modified.csv
	tail -n4 invest-sample-data/Carbon/carbon_pools_willamette.csv >> invest-sample-data/Carbon/carbon_pools_willamette_modified.csv

	head -n7 invest-sample-data/WaveEnergy/input/Machine_Pelamis_Performance.csv > invest-sample-data/WaveEnergy/input/Machine_Pelamis_Performance_modified.csv

	head -n4 invest-sample-data/WindEnergy/input/NE_sub_pts.csv > invest-sample-data/WindEnergy/input/NE_sub_pts_modified.csv
