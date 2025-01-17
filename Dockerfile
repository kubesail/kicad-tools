# Portions Copyright 2019 Productize SPRL
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
#
# This docker configuration was originally based on https://github.com/productize/docker-kicad as of 301bf181b72c811e9644b83a895ec4a16f2fa1a0


FROM ubuntu:bionic
MAINTAINER Jesse Vincent <jesse@keyboard.io>
LABEL Description="Minimal KiCad image based on Ubuntu"
LABEL org.opencontainers.image.source https://github.com/obra/kicad-tools

COPY upstream/kicad-automation-scripts/eeschema/requirements.txt .
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
        apt-get -y update && \
        apt-get install -y software-properties-common && \
        add-apt-repository --yes ppa:kicad/kicad-dev-nightly && \
        apt-get -y update && \
        apt-get install -y kicad-nightly python python-pip python3-pip xvfb recordmydesktop xdotool xclip imagemagick && \
        pip install -r requirements.txt && \
        apt-get -y autoremove && \
        rm -rf /var/lib/apt/lists/* && \
        rm -rf /usr/lib/kicad-nightly/share/kicad/3dmodels && \
        rm requirements.txt && \
        sed -i '/disable ghostscript format types/d' /etc/ImageMagick-6/policy.xml && \
        sed -i '/\"PS\"/d' /etc/ImageMagick-6/policy.xml && \
        sed -i '/\"EPS\"/d' /etc/ImageMagick-6/policy.xml && \
        sed -i '/\"PDF\"/d' /etc/ImageMagick-6/policy.xml && \
        sed -i '/\"XPS\"/d' /etc/ImageMagick-6/policy.xml

# Use a UTF-8 compatible LANG because KiCad 5 uses UTF-8 in the PCBNew title
# This causes a "failure in conversion from UTF8_STRING to ANSI_X3.4-1968" when
# attempting to look for the window name with xdotool.
ENV LANG C.UTF-8

COPY upstream/kicad-automation-scripts /usr/lib/python2.7/dist-packages/kicad-automation

# Copy default configuration and fp_lib_table to prevent first run dialog
# KiCad 6 has no default hotkey for opening the BOM window, so we'll copy in the user.hotkeys file to make scripting easier
COPY upstream/kicad-automation-scripts/config/5.99 /root/.config/kicad/5.99/

# Copy in a custom JLCPCB BOM generator script
COPY upstream/kicad-automation-scripts/config/jlcpcb_bom.py /usr/share/kicad-nightly/plugins

# Copy the installed global symbol and footprint so projects built with stock
# symbols and footprints don't break
RUN cp /usr/share/kicad-nightly/template/sym-lib-table /root/.config/kicad/
RUN cp /usr/share/kicad-nightly/template/fp-lib-table /root/.config/kicad/



# Install KiPlot

COPY upstream/kiplot /opt/kiplot

RUN cd /opt/kiplot && pip3 install -e . 

COPY etc/kiplot /opt/etc/kiplot


# Install KiCost
#
# Disabled because KiCost depends on Octopart which no longer has a free API
#RUN pip3 install 'kicost==1.0.4'
#
#RUN apt-get -y remove python3-pip && \
#    rm -rf /var/lib/apt/lists/*
#

# Install the interactive BOM

COPY upstream/InteractiveHtmlBom /opt/InteractiveHtmlBom
COPY scripts/make-interactive-bom /opt/InteractiveHtmlBom/


COPY bin-on-docker/git-diff-boards.sh /opt/diff-boards/
#COPY bin/git-imgdiff /opt/diff-boards/
COPY bin-on-docker/plot_board.py /opt/diff-boards/
COPY bin-on-docker/pcb-diff.sh /opt/diff-boards/
COPY bin-on-docker/schematic-diff.sh /opt/diff-boards/

COPY bin-on-docker/fill_zones.py /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["bash", "/entrypoint.sh"]
CMD ["bom"]
