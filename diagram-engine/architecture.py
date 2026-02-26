from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import EC2, EC2AutoScaling, ECR
from diagrams.onprem.ci import Jenkins
from diagrams.onprem.vcs import Github


graph_attr = {
    "fontname": "Inter, Helvetica, Arial, sans-serif",
    "fontsize": "16",
    "nodesep": "1.0",
    "ranksep": "1.5",
    "bgcolor": "#F7F9FC",
    "pad": "0.5"
}

node_attr = {
    "fontname": "Inter, Helvetica, Arial, sans-serif",
    "fontsize": "12"
}

edge_attr = {
    "fontname": "Inter, Helvetica, Arial, sans-serif",
    "fontsize": "11"
}

# DIRECTIONAL FLOW
with Diagram("AWS CI/CD Pipeline with Dynamic Jenkins Spot Agents", 
             show=False, 
             direction="LR", 
             graph_attr=graph_attr,
             node_attr=node_attr,
             edge_attr=edge_attr):

    # EXTERNAL SOURCES
    source_code = Github("Git Repo\n(Source Code)")

    # ARCHITECTURE CLUSTERING
    with Cluster("AWS Cloud Environment", graph_attr={"bgcolor": "#FFFFFF", "pencolor": "#FF9900", "penwidth": "2.0"}):
        
        ecr = ECR("Amazon ECR\n(Docker Images)")

        with Cluster("VPC (Virtual Private Cloud)", graph_attr={"bgcolor": "#F4F5F7", "style": "dashed", "pencolor": "#3F8624"}):
            
            with Cluster("CI/CD Subnet", graph_attr={"bgcolor": "#E8EFFD", "pencolor": "#4A90E2"}):
                jenkins_master = Jenkins("Jenkins Controller")
                asg = EC2AutoScaling("Auto Scaling Group\n(EC2 Fleet)")
                jenkins_agents = EC2("Jenkins Agents\n(Spot Instances)")
                
            with Cluster("Application Subnet", graph_attr={"bgcolor": "#E9F5EB", "pencolor": "#27AE60"}):
                app_host = EC2("Application Host\n(EC2)")

    # INTERACTIONS / THE CI/CD FLOW
    source_code >> Edge(label="1. Code Commit", color="#24292E", fontcolor="#24292E", style="bold") >> jenkins_master
    jenkins_master >> Edge(label="2. Provision Agent", color="#D32D41", fontcolor="#D32D41", style="dashed") >> asg
    asg >> Edge(label="3. Spin Up", color="#D32D41", fontcolor="#D32D41", style="bold") >> jenkins_agents
    jenkins_agents >> Edge(label="4. Checkout", color="#24292E", fontcolor="#24292E", style="dashed") >> source_code
    jenkins_agents >> Edge(label="5. Build & Push", color="#1D63ED", fontcolor="#1D63ED", style="bold") >> ecr
    jenkins_agents >> Edge(label="6. Deploy Command (SSH)", color="#FF9900", fontcolor="#FF9900", style="dashed") >> app_host
    app_host >> Edge(label="7. Pull Image", color="#1D63ED", fontcolor="#1D63ED", style="bold") >> ecr
