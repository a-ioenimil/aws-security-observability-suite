from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import EC2, EC2AutoScaling, ECR
from diagrams.aws.network import VPC, PublicSubnet, PrivateSubnet, ALB
from diagrams.aws.security import Guardduty
from diagrams.aws.storage import S3
from diagrams.aws.management import Cloudwatch, Cloudtrail
from diagrams.aws.general import User, InternetAlt1
from diagrams.onprem.vcs import Git
from diagrams.onprem.ci import Jenkins
from diagrams.onprem.monitoring import Prometheus, Grafana
from diagrams.saas.chat import Slack
from diagrams.programming.framework import Fastapi
from diagrams.generic.os import LinuxGeneral

graph_attr = {
    "dpi": "300",
    "fontname": "Inter, Helvetica, Arial, sans-serif",
    "fontsize": "18",
    "nodesep": "1.2",
    "ranksep": "1.5",
    "pad": "1.0",
    "splines": "ortho"
}

node_attr = {
    "fontname": "Inter, Helvetica, Arial, sans-serif",
    "fontsize": "12",
}

edge_attr = {
    "fontname": "Inter, Helvetica, Arial, sans-serif",
    "fontsize": "11",
}

with Diagram(
    "AWS Security & Observability CI/CD Architecture", 
    show=False, 
    direction="LR", 
    graph_attr=graph_attr,
    node_attr=node_attr,
    edge_attr=edge_attr,
    filename="aws_security_observability_architecture"
):
    
    # External / Out of VPC Sources
    developer = User("Developer")
    git = Git("Git Repository")
    internet = InternetAlt1("Internet / Users")
    slack = Slack("Slack Alerts")

    with Cluster("AWS Cloud", graph_attr={"bgcolor": "#FFFFFF", "pencolor": "#FF9900", "penwidth": "2.0"}):

        with Cluster("Global & Regional Services / Security", graph_attr={"bgcolor": "#F9F9F9", "pencolor": "#8C4FFF", "style": "dashed"}):
            cloudtrail = Cloudtrail("AWS CloudTrail\n(Activity Logging)")
            s3_logs = S3("S3 Bucket\n(30d IA / 90d Del)")
            cloudwatch = Cloudwatch("CloudWatch Logs\n(Container Logs)")
            guardduty = Guardduty("AWS GuardDuty\n(Threat Detection)")
            ecr = ECR("Amazon ECR\n(Docker Registry)")

        with Cluster("VPC", graph_attr={"bgcolor": "#E8F4F8", "style": "solid", "pencolor": "#3F8624"}):
            alb = ALB("Application Load Balancer\n(Ports 80, 3000, 9090,\n9093, 9100)")

            with Cluster("Public Subnet", graph_attr={"bgcolor": "#D4E6F1", "pencolor": "#4A90E2"}):
                with Cluster("Jenkins Cluster"):
                    jenkins_controller = Jenkins("Jenkins Controller\n(EC2)")
                    
            with Cluster("Private Subnet", graph_attr={"bgcolor": "#D6EAF8", "pencolor": "#2980B9"}):
                with Cluster("Jenkins Agents Cluster"):
                    jenkins_agents = EC2AutoScaling("Spot Agents\n(ASG)")
                
                with Cluster("App Compute Cluster"):
                    app_host = EC2("App Host (EC2)")
                    
                    with Cluster("Docker Compose Stack", graph_attr={"bgcolor": "#E9F5EB"}):
                        fastapi = Fastapi("Backend API\n(:80)")
                        grafana = Grafana("Grafana\n(:3000)")
                        prometheus = Prometheus("Prometheus\n(:9090)")
                        alertmanager = Prometheus("Alertmanager\n(:9093)") 
                        node_exporter = LinuxGeneral("Node Exporter\n(:9100)")

    # Data Flows (Edges)

    # 1. Build Flow
    developer >> Edge(color="darkgreen", style="bold", label="Push Code") >> git
    git >> Edge(color="darkblue", style="bold", label="Webhook Trigger") >> jenkins_controller
    jenkins_controller >> Edge(color="darkblue", style="dashed", label="Orchestrates & Provisions") >> jenkins_agents
    jenkins_agents >> Edge(color="darkblue", style="dashed", label="Pulls Code & Tests") >> git
    jenkins_agents >> Edge(color="darkgreen", style="bold", label="Builds & Pushes Image") >> ecr

    # 2. Deploy Flow
    jenkins_controller >> Edge(color="purple", style="bold", label="SSH Config Deploy") >> app_host
    app_host >> Edge(color="purple", style="dashed", label="Pulls Image & Runs Stack") >> ecr

    # 3. Traffic Routing
    internet >> Edge(color="orange", style="bold", label="HTTP Requests") >> alb
    alb >> Edge(color="orange", style="bold", label="Port 80") >> fastapi
    alb >> Edge(color="orange", style="bold", label="Port 3000") >> grafana
    alb >> Edge(color="orange", style="bold", label="Port 9090") >> prometheus
    alb >> Edge(color="orange", style="bold", label="Port 9093") >> alertmanager
    alb >> Edge(color="orange", style="bold", label="Port 9100") >> node_exporter

    # 4. Metrics Flow
    prometheus >> Edge(color="firebrick", style="dashed", label="Scrapes API (:80)") >> fastapi
    prometheus >> Edge(color="firebrick", style="dashed", label="Scrapes Host Metrics (:9100)") >> node_exporter

    # 5. Alerting Flow
    prometheus >> Edge(color="red", style="bold", label="Threshold Alerts") >> alertmanager
    alertmanager >> Edge(color="red", style="bold", label="Pushes Webhook") >> slack

    # 6. Logging Flow
    fastapi >> Edge(color="brown", style="dashed", label="awslogs driver") >> cloudwatch
    prometheus >> Edge(color="brown", style="dashed", label="awslogs driver") >> cloudwatch

    # 7. Security Flow
    cloudtrail >> Edge(color="black", style="bold", label="Stores Encrypted Logs") >> s3_logs
    guardduty >> Edge(color="black", style="dotted", label="Monitors AWS Account / VPC") >> alb
    guardduty >> Edge(color="black", style="dotted", label="Monitors AWS Account / VPC") >> app_host
