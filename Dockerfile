# Use the latest official Python image as the base image
FROM python:latest

# Install wget and ca-certificates for downloading OpenJDK
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends wget ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Manually download and install OpenJDK
ENV JAVA_HOME=/opt/java/openjdk

RUN mkdir -p "${JAVA_HOME}" && \
    wget -O openjdk.tar.gz "https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-aarch64_bin.tar.gz" && \
    tar -xzf openjdk.tar.gz --directory "${JAVA_HOME}" --strip-components=1 && \
    rm openjdk.tar.gz && \
    update-alternatives --install /usr/bin/java java "${JAVA_HOME}/bin/java" 100 && \
    update-alternatives --install /usr/bin/javac javac "${JAVA_HOME}/bin/javac" 100

# Set environment variables
ENV PATH="${JAVA_HOME}/bin:${PATH}" \
    SPARK_HOME=/spark

# Download and install Spark
RUN mkdir /spark && \
    cd /spark && \
    wget --no-verbose https://downloads.apache.org/spark/spark-3.5.1/spark-3.5.1-bin-hadoop3.tgz && \
    tar -xzf spark-3.5.1-bin-hadoop3.tgz --strip-components=1 && \
    rm spark-3.5.1-bin-hadoop3.tgz

# Add Spark to PATH
ENV PATH=$PATH:/spark/bin

# Install Python libraries
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir pyspark apache-airflow beautifulsoup4 pandas requests

# Copy your scripts and DAGs to the container
COPY scripts/pyspark_keywords.py /scripts/pyspark_keywords.py
COPY scripts/product_hunt_scraper.py /scripts/product_hunt_scraper.py
COPY dags/airflow-dag.py /airflow/dags/airflow-dag.py
COPY scripts/stopwords.txt /scripts/stopwords.txt

# Set the working directory
WORKDIR /scripts

# Expose the port Airflow webserver runs on
EXPOSE 8080

# Command to run on container start
CMD ["airflow", "webserver"]