
variable "accounts" {
  description = "A collection of accounts to nuke"
  type        = list(string)
}

variable "regions" {
  description = "A collection of regions to nuke"
  type        = list(string)
}

variable "blocklist" {
  description = "A collection of resources to block from deletion"
  type        = list(string)
  default     = ["123456789012"]
}

variable "presets" {
  description = "A collection of presets used in the nuke"
  type = map(map(list(object({
    property = string
    type     = string
    value    = string
  }))))
  default = {}
}

variable "include_presets" {
  description = "A collection of preset filters to use for nuke"
  type = object({
    enable_control_tower     = optional(bool, true)
    enable_cost_intelligence = optional(bool, true)
    enable_landing_zone      = optional(bool, true)
  })
  default = {
    enable_control_tower     = true
    enable_cost_intelligence = true
    enable_landing_zone      = true
  }
}

variable "filters" {
  description = "A collection of global filters are applied to all resources"
  type = list(object({
    property = string
    type     = string
    value    = string
  }))
  default = []
}

variable "included" {
  description = "A collection of resources to include in the nuke"
  type = object({
    add = optional(list(string), [])
    # Resources to remove from the nuke configuration
    all = optional(list(string), [
      "AWSBackupRecoveryPoint",
      "AWSBackupSelection",
      "BackupVault",
      "AppStreamDirectoryConfig",
      "AppStreamFleet",
      "AppStreamFleetState",
      "AppStreamImage",
      "AppStreamImageBuilder",
      "AppStreamImageBuilderWaiter",
      "AppStreamStack",
      "AppStreamStackFleetAttachment",
      "AutoScalingGroup",
      "AutoScalingPlansScalingPlan",
      "BatchComputeEnvironment",
      "BatchComputeEnvironmentState",
      "BatchJobQueue",
      "BatchJobQueueState",
      "Cloud9Environment",
      "CloudDirectoryDirectory",
      "CloudDirectorySchema",
      "CloudFrontDistribution",
      "CloudFrontDistributionDeployment",
      "CloudHSMV2Cluster",
      "CloudHSMV2ClusterHSM",
      "CloudSearchDomain",
      "CloudWatchAlarm",
      "CloudWatchDashboard",
      "CloudWatchLogsDestination",
      "CloudWatchLogsLogGroup",
      "CodeBuildProject",
      "CodeCommitRepository",
      "CodeDeployApplication",
      "CodePipelinePipeline",
      "CodeStarProject",
      "CognitoIdentityPool",
      "CognitoUserPool",
      "CognitoUserPoolDomain",
      "DAXCluster",
      "DAXParameterGroup",
      "DAXSubnetGroup",
      "DataPipelinePipeline",
      "DatabaseMigrationServiceCertificate",
      "DatabaseMigrationServiceEndpoint",
      "DatabaseMigrationServiceEventSubscription",
      "DatabaseMigrationServiceReplicationInstance",
      "DatabaseMigrationServiceReplicationTask",
      "DatabaseMigrationServiceSubnetGroup",
      "DeviceFarmProject",
      "DirectoryServiceDirectory",
      "DynamoDBTable",
      "EC2Address",
      "EC2ClientVpnEndpoint",
      "EC2ClientVpnEndpointAttachment",
      "EC2CustomerGateway",
      "EC2Image",
      "EC2Instance",
      "EC2InternetGateway",
      "EC2InternetGatewayAttachment",
      "EC2KeyPair",
      "EC2LaunchTemplate",
      "EC2NATGateway",
      "EC2NetworkACL",
      "EC2PlacementGroup",
      "EC2RouteTable",
      "EC2SecurityGroup",
      "EC2Snapshot",
      "EC2SpotFleetRequest",
      "EC2Subnet",
      "EC2TGW",
      "EC2TGWAttachment",
      "EC2VPC",
      "EC2VPCEndpoint",
      "EC2VPCEndpointServiceConfiguration",
      "EC2VPCPeeringConnection",
      "EC2VPNConnection",
      "EC2VPNGatewayAttachment",
      "EC2Volume",
      "ECRRepository",
      "EFSFileSystem",
      "EFSMountTarget",
      "EKSCluster",
      "ELB",
      "ELBv2",
      "ELBv2TargetGroup",
      "EMRCluster",
      "EMRSecurityConfiguration",
      "ESDomain",
      "ElasticBeanstalkApplication",
      "ElasticBeanstalkEnvironment",
      "ElasticTranscoderPipeline",
      "ElasticacheCacheCluster",
      "ElasticacheReplicationGroup",
      "ElasticacheSubnetGroup",
      "FSxBackup",
      "FSxFileSystem",
      "FirehoseDeliveryStream",
      "GlueClassifier",
      "GlueConnection",
      "GlueCrawler",
      "GlueDatabase",
      "GlueDevEndpoint",
      "GlueJob",
      "GlueTrigger",
      "IAMGroup",
      "IAMGroupPolicy",
      "IAMGroupPolicyAttachment",
      "IAMInstanceProfile",
      "IAMInstanceProfileRole",
      "IAMLoginProfile",
      "IAMOpenIDConnectProvider",
      "IAMRole",
      "IAMServerCertificate",
      "IAMServiceSpecificCredential",
      "IAMUser",
      "IAMUserAccessKey",
      "IAMUserGroupAttachment",
      "IAMUserPolicy",
      "IAMUserPolicyAttachment",
      "IAMVirtualMFADevice",
      "IoTAuthorizer",
      "IoTCACertificate",
      "IoTCertificate",
      "IoTJob",
      "IoTOTAUpdate",
      "IoTPolicy",
      "IoTRoleAlias",
      "IoTStream",
      "IoTThing",
      "IoTThingGroup",
      "IoTThingType",
      "IoTThingTypeState",
      "IoTTopicRule",
      "KMSAlias",
      "KMSKey",
      "KinesisAnalyticsApplication",
      "KinesisStream",
      "KinesisVideoProject",
      "LambdaEventSourceMapping",
      "LambdaFunction",
      "LaunchConfiguration",
      "LifecycleHook",
      "LightsailDisk",
      "LightsailDomain",
      "LightsailInstance",
      "LightsailKeyPair",
      "LightsailLoadBalancer",
      "LightsailStaticIP",
      "MQBroker",
      "MSKCluster",
      "MediaConvertJobTemplate",
      "MediaConvertPreset",
      "MediaConvertQueue",
      "MediaLiveChannel",
      "MediaLiveInput",
      "MediaLiveInputSecurityGroup",
      "MediaPackageChannel",
      "MediaPackageOriginEndpoint",
      "MediaStoreContainer",
      "MediaStoreDataItems",
      "MediaTailorConfiguration",
      "MobileProject",
      "NeptuneCluster",
      "NeptuneInstance",
      "NetpuneSnapshot",
      "OpsWorksApp",
      "OpsWorksCMBackup",
      "OpsWorksCMServer",
      "OpsWorksCMServerState",
      "OpsWorksInstance",
      "OpsWorksLayer",
      "OpsWorksUserProfile",
      "RDSDBCluster",
      "RDSDBClusterParameterGroup",
      "RDSDBParameterGroup",
      "RDSDBSubnetGroup",
      "RDSInstance",
      "RDSSnapshot",
      "RedshiftCluster",
      "RedshiftParameterGroup",
      "RedshiftSnapshot",
      "RedshiftSubnetGroup",
      "RekognitionCollection",
      "ResourceGroupGroup",
      "RoboMakerDeploymentJob",
      "RoboMakerFleet",
      "RoboMakerRobot",
      "RoboMakerRobotApplication",
      "RoboMakerSimulationApplication",
      "RoboMakerSimulationJob",
      "Route53HostedZone",
      "Route53ResourceRecordSet",
      "S3Bucket",
      "S3MultipartUpload",
      "S3Object",
      "SESConfigurationSet",
      "SESIdentity",
      "SESReceiptFilter",
      "SESReceiptRuleSet",
      "SESTemplate",
      "SFNStateMachine",
      "SNSEndpoint",
      "SNSPlatformApplication",
      "SNSSubscription",
      "SNSTopic",
      "SQSQueue",
      "SSMActivation",
      "SSMAssociation",
      "SSMDocument",
      "SSMMaintenanceWindow",
      "SSMParameter",
      "SSMPatchBaseline",
      "SSMResourceDataSync",
      "SageMakerEndpoint",
      "SageMakerEndpointConfig",
      "SageMakerModel",
      "SageMakerNotebookInstance",
      "SageMakerNotebookInstanceState",
      "SecretsManagerSecret",
      "ServiceCatalogConstraintPortfolioAttachment",
      "ServiceCatalogPortfolio",
      "ServiceCatalogPortfolioProductAttachment",
      "ServiceCatalogPortfolioShareAttachment",
      "ServiceCatalogPrincipalPortfolioAttachment",
      "ServiceCatalogProduct",
      "ServiceCatalogProvisionedProduct",
      "ServiceCatalogTagOption",
      "ServiceCatalogTagOptionPortfolioAttachment",
      "ServiceDiscoveryInstance",
      "ServiceDiscoveryNamespace",
      "ServiceDiscoveryService",
      "SimpleDBDomain",
      "StorageGatewayFileShare",
      "StorageGatewayGateway",
      "StorageGatewayTape",
      "StorageGatewayVolume",
      "WAFRegionalByteMatchSet",
      "WAFRegionalByteMatchSetIP",
      "WAFRegionalIPSet",
      "WAFRegionalIPSetIP",
      "WAFRegionalRateBasedRule",
      "WAFRegionalRateBasedRulePredicate",
      "WAFRegionalRegexMatchSet",
      "WAFRegionalRegexMatchTuple",
      "WAFRegionalRegexPatternSet",
      "WAFRegionalRegexPatternString",
      "WAFRegionalRule",
      "WAFRegionalRulePredicate",
      "WAFRegionalWebACL",
      "WAFRegionalWebACLRuleAttachment",
      "WAFRule",
      "WAFWebACL",
      "WAFWebACLRuleAttachment",
      "WorkLinkFleet",
      "WorkSpacesWorkspace",
    ])
    # A collection of resources to include in the nuke 
  })
  default = {}
}

variable "excluded" {
  description = "A collection of resources to exclude from the nuke"
  type = object({
    add = optional(list(string), [])
    # Additional resources to exclude from the nuke configuration on top of the default ones below
    remove = optional(list(string), [])
    # Resources to exclude from the nuke configuration 
    all = optional(list(string), [
      "Cloud9Environment",
      "CloudSearchDomain",
      "CodeStarConnection",
      "CodeStarNotification",
      "CodeStarProject",
      "EC2DHCPOption",
      "EC2NetworkACL",
      "EC2NetworkInterface",
      "ECSCluster",
      "ECSClusterInstance",
      "ECSService",
      "ECSTaskDefinition",
      "FMSNotificationChannel",
      "FMSPolicy",
      "IAMUser",
      "MachineLearningBranchPrediction",
      "MachineLearningDataSource",
      "MachineLearningEvaluation",
      "MachineLearningMLModel",
      "OpsWorksApp",
      "OpsWorksCMBackup",
      "OpsWorksCMServer",
      "OpsWorksCMServerState",
      "OpsWorksInstance",
      "OpsWorksLayer",
      "OpsWorksUserProfile",
      "RedshiftServerlessNamespace",
      "RedshiftServerlessSnapshot",
      "RedshiftServerlessWorkgroup",
      "RoboMakerDeploymentJob",
      "RoboMakerFleet",
      "RoboMakerRobot",
      "RoboMakerRobotApplication",
      "RoboMakerSimulationApplication",
      "RoboMakerSimulationJob",
      "S3Object",
      "ServiceCatalogTagOption",
      "ServiceCatalogTagOptionPortfolioAttachment",
    ])
    ## Default resources to exclude from the nuke configuration 
  })
  default = {}
}

