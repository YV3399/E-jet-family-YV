#!/bin/bash
xsltproc --stringparam index 0 Systems/pfd.xsl <(echo '<xml/>') >Systems/pfd1.xml
xsltproc --stringparam index 1 Systems/pfd.xsl <(echo '<xml/>') >Systems/pfd2.xml
xsltproc --stringparam index 0 Systems/iru.xsl <(echo '<xml/>') >Systems/iru1.xml
xsltproc --stringparam index 1 Systems/iru.xsl <(echo '<xml/>') >Systems/iru2.xml
