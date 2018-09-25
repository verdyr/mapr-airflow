FROM maprtech/pacc:6.0.1_5.0.0_centos7


ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=0 \
    JAVA_VERSION_BUILD=141 \
    GRADLE_VERSION_MAJOR=4 \
    GRADLE_VERSION_MINOR=10 \
    SBT_VERSION_MAJOR=1 \
    SBT_VERSION_MINOR=2 \
    SBT_VERSION_MINOR_MINOR=2

ENV SLUGIFY_USES_TEXT_UNIDECODE=yes

RUN yum upgrade python-setuptools
RUN yum install -y python-pip git java-1.${JAVA_VERSION_MAJOR}.${JAVA_VERSION_MINOR} maven gcc gcc-c++ libffi-devel python-devel python-pip python-wheel openssl-devel libsasl2-devel openldap-devel cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-md5 cyrus-sasl-plain

RUN yum install -y mapr-spark

RUN mkdir /tmp/build-dir
WORKDIR /tmp/build-dir
RUN wget https://package.mapr.com/releases/MEP/MEP-5.0.0/redhat/mapr-drill-internal-1.13.0.201803281600-1.noarch.rpm
RUN wget https://package.mapr.com/releases/MEP/MEP-5.0.0/redhat/mapr-drill-1.13.0.201803281600-1.noarch.rpm
RUN rpm -Uvh mapr-drill-internal-1.13.0.201803281600-1.noarch.rpm
RUN rpm -Uvh --nodeps mapr-drill-1.13.0.201803281600-1.noarch.rpm


RUN pip install --upgrade setuptools pip
RUN pip install apache-airflow apache-airflow[hive] hmsclient

RUN cd /tmp/build-dir && git clone https://github.com/mapr-demos/mapr-airflow.git && cd mapr-airflow/spark-statistics-job && mvn clean package
RUN cd /tmp/build-dir/mapr-airflow

# Workaround for 'hive_hooks' beeline issue
RUN sed -i -e "s/{hql}/{hql}\\\n/g" /usr/lib/python2.7/site-packages/airflow/hooks/hive_hooks.py

# Create a directory for your MapR Application and copy the Application
RUN mkdir -p /home/mapr/mapr-apps/mapr-airflow

COPY /tmp/build-dir/mapr-airflow/bin /home/mapr/mapr-apps/mapr-airflow/bin
COPY /tmp/build-dir/mapr-airflow/dags /home/mapr/mapr-apps/mapr-airflow/dags
COPY /tmp/build-dir/mapr-airflow/spark-statistics-job/target/spark-statistics-job-1.0.0-SNAPSHOT.jar /home/mapr/mapr-apps/spark-statistics-job-1.0.0-SNAPSHOT.jar
RUN chmod +x /home/mapr/mapr-apps/mapr-airflow/bin/run.sh

CMD ["/home/mapr/mapr-apps/mapr-airflow/bin/run.sh"]
