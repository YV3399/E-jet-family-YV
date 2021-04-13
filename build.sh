#!/bin/bash
xsltproc --stringparam index 0 Systems/pfd.xsl <(echo '<xml/>') >Systems/pfd1.xml
xsltproc --stringparam index 1 Systems/pfd.xsl <(echo '<xml/>') >Systems/pfd2.xml
