from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from airflow.utils.dates import days_ago
from datetime import timedelta
import os

# Define the default DAG arguments.
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email': [os.getenv('EMAIL')],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Define the DAG, its scheduling, and set catchup to False if you don't want backfilling.
dag = DAG(
    'run_pyspark_script_via_bash',
    default_args=default_args,
    description='An Airflow DAG to run a PySpark script using BashOperator.',
    schedule_interval=timedelta(days=1),
    start_date=days_ago(1),
    catchup=False,
)

# Dynamically determine the path of the scripts directory relative to this DAG file.
dag_dir = os.path.dirname(__file__)
scripts_dir = os.path.join(dag_dir, '../scripts')
script_path = os.path.join(scripts_dir, 'pyspark_keywords.py')

# Ensure the script path is absolute and resolve any symbolic links.
absolute_script_path = os.path.abspath(script_path)
print(absolute_script_path)
# Define the task to run your PySpark script using the BashOperator.
run_script_task = BashOperator(
    task_id='run_pyspark_script',
    # Ensure the spark-submit command is correctly specified for your environment
    # You might need to specify the full path to spark-submit if it's not in $PATH
    # Also, ensure your script path is correct and accessible from the Airflow worker
    bash_command=f'spark-submit --packages org.apache.hadoop:hadoop-aws:3.3.1,com.amazonaws:aws-java-sdk-bundle:1.11.375 {absolute_script_path}',
    dag=dag,
)

# Set the task sequence.
run_script_task