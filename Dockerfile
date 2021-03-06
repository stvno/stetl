FROM osgeo/gdal:ubuntu-small-latest

LABEL maintainer="Just van den Broecke <justb4@gmail.com>"

#
# ARGS
#
ARG TIMEZONE="Europe/Amsterdam"
ARG LOCALE="en_US.UTF-8"

# ARG ADD_PYTHON_DEB_PACKAGES="python-scipy python-seaborn python-matplotlib"
ARG ADD_PYTHON_DEB_PACKAGES=""
# ARG ADD_PYTHON_PIP_PACKAGES="scikit-learn==0.18"
ARG ADD_PYTHON_PIP_PACKAGES=""
#
# ENV settings
#
ENV TZ=${TIMEZONE} \
   DEBIAN_FRONTEND="noninteractive" \
   BUILD_DEPS="tzdata build-essential apt-utils" \
   PYTHON_CORE_PACKAGES="locales python3-requests python3-tz python3-numpy python3-pandas python3-setuptools python3-pip python3-lxml python3-psycopg2 python3-jinja2" \
   PYTHON_EXTRA_DEB_PACKAGES="${ADD_PYTHON_DEB_PACKAGES}"  \
   PYTHON_EXTRA_PIP_PACKAGES="${ADD_PYTHON_PIP_PACKAGES}"

# Add Source Code
ADD . /stetl

# Set time right and configure timezone and locale
RUN \
	apt-get update \
	&& apt-get --no-install-recommends install  -y \
		${BUILD_DEPS} \
	    ${PYTHON_CORE_PACKAGES} \
	    ${PYTHON_EXTRA_DEB_PACKAGES} \
	# Timezone
	&& cp /usr/share/zoneinfo/${TZ} /etc/localtime\
	&& dpkg-reconfigure tzdata \
	# Locale
	&& sed -i -e "s/# ${LOCALE} UTF-8/${LOCALE} UTF-8/" /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=${LOCALE} \
    # Install GDAL version matching installed binary - MESSY - need cleaner solution!
    # && pip3 install GDAL==`gdalinfo --version | cut -d' ' -f2 | cut -d',' -f1` \
    && export CPLUS_INCLUDE_PATH=/usr/include/gdal \
    && export C_INCLUDE_PATH=/usr/include/gdal \
    # Optional packages to install via Pip
	&& if [ "x${PYTHON_EXTRA_PIP_PACKAGES}" = "x" ] ;\
	    then \
	        echo "No extra Pip packages to install" ;\
	    else \
	        pip3 install ${PYTHON_EXTRA_PIP_PACKAGES} ;\
	    fi  \
	# Install and Remove build-related packages for smaller image size
	&& cd /stetl \
		&& python3 setup.py install  \
		&& apt-get remove --purge ${BUILD_DEPS} -y \
		&& apt autoremove -y  \
        && rm -rf /var/lib/apt/lists/*

ENV LANG="${LOCALE}" LANGUAGE="${LOCALE}"  PYTHONPATH="/stetl/stetl" \
   STETL_HOME="/stetl/stetl"

RUN echo "For ${TZ} date=`date`" && echo "Locale=`locale`"

# Run examples
# docker run --rm -it geopython/stetl stetl
# docker run --rm -v $(pwd):/work -w /work geopython/stetl:2.0 stetl -c etl.cfg
