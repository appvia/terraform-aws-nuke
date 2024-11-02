<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.7 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accounts"></a> [accounts](#input\_accounts) | A collection of accounts to nuke | `list(string)` | n/a | yes |
| <a name="input_regions"></a> [regions](#input\_regions) | A collection of regions to nuke | `list(string)` | n/a | yes |
| <a name="input_blocklist"></a> [blocklist](#input\_blocklist) | A collection of resources to block from deletion | `list(string)` | <pre>[<br/>  "123456789012"<br/>]</pre> | no |
| <a name="input_excluded"></a> [excluded](#input\_excluded) | A collection of resources to exclude from the nuke | <pre>object({<br/>    add = optional(list(string), [])<br/>    # Additional resources to exclude from the nuke configuration on top of the default ones below<br/>    remove = optional(list(string), [])<br/>    # Resources to exclude from the nuke configuration <br/>    all = optional(list(string), [<br/>      "Cloud9Environment",<br/>      "CloudSearchDomain",<br/>      "CodeStarConnection",<br/>      "CodeStarNotification",<br/>      "CodeStarProject",<br/>      "EC2DHCPOption",<br/>      "EC2NetworkACL",<br/>      "EC2NetworkInterface",<br/>      "ECSCluster",<br/>      "ECSClusterInstance",<br/>      "ECSService",<br/>      "ECSTaskDefinition",<br/>      "FMSNotificationChannel",<br/>      "FMSPolicy",<br/>      "IAMUser",<br/>      "MachineLearningBranchPrediction",<br/>      "MachineLearningDataSource",<br/>      "MachineLearningEvaluation",<br/>      "MachineLearningMLModel",<br/>      "OpsWorksApp",<br/>      "OpsWorksCMBackup",<br/>      "OpsWorksCMServer",<br/>      "OpsWorksCMServerState",<br/>      "OpsWorksInstance",<br/>      "OpsWorksLayer",<br/>      "OpsWorksUserProfile",<br/>      "RedshiftServerlessNamespace",<br/>      "RedshiftServerlessSnapshot",<br/>      "RedshiftServerlessWorkgroup",<br/>      "RoboMakerDeploymentJob",<br/>      "RoboMakerFleet",<br/>      "RoboMakerRobot",<br/>      "RoboMakerRobotApplication",<br/>      "RoboMakerSimulationApplication",<br/>      "RoboMakerSimulationJob",<br/>      "S3Object",<br/>      "ServiceCatalogTagOption",<br/>      "ServiceCatalogTagOptionPortfolioAttachment",<br/>    ])<br/>    ## Default resources to exclude from the nuke configuration <br/>  })</pre> | `{}` | no |
| <a name="input_filters"></a> [filters](#input\_filters) | A collection of filters are applied to all resources | <pre>list(object({<br/>    property = string<br/>    type     = string<br/>    value    = string<br/>  }))</pre> | `[]` | no |
| <a name="input_include_presets"></a> [include\_presets](#input\_include\_presets) | A collection of preset filters to use for nuke | <pre>object({<br/>    enable_control_tower     = optional(bool, true)<br/>    enable_cost_intelligence = optional(bool, true)<br/>    enable_landing_zone      = optional(bool, true)<br/>  })</pre> | <pre>{<br/>  "enable_control_tower": true,<br/>  "enable_cost_intelligence": true,<br/>  "enable_landing_zone": true<br/>}</pre> | no |
| <a name="input_included"></a> [included](#input\_included) | A collection of resources to include in the nuke | <pre>object({<br/>    add = optional(list(string), [])<br/>    # Resources to remove from the nuke configuration<br/>    all = optional(list(string), [<br/>      "AWSBackupRecoveryPoint",<br/>      "AWSBackupSelection",<br/>      "BackupVault",<br/>      "AppStreamDirectoryConfig",<br/>      "AppStreamFleet",<br/>      "AppStreamFleetState",<br/>      "AppStreamImage",<br/>      "AppStreamImageBuilder",<br/>      "AppStreamImageBuilderWaiter",<br/>      "AppStreamStack",<br/>      "AppStreamStackFleetAttachment",<br/>      "AutoScalingGroup",<br/>      "AutoScalingPlansScalingPlan",<br/>      "BatchComputeEnvironment",<br/>      "BatchComputeEnvironmentState",<br/>      "BatchJobQueue",<br/>      "BatchJobQueueState",<br/>      "Cloud9Environment",<br/>      "CloudDirectoryDirectory",<br/>      "CloudDirectorySchema",<br/>      "CloudFrontDistribution",<br/>      "CloudFrontDistributionDeployment",<br/>      "CloudHSMV2Cluster",<br/>      "CloudHSMV2ClusterHSM",<br/>      "CloudSearchDomain",<br/>      "CloudWatchAlarm",<br/>      "CloudWatchDashboard",<br/>      "CloudWatchLogsDestination",<br/>      "CloudWatchLogsLogGroup",<br/>      "CodeBuildProject",<br/>      "CodeCommitRepository",<br/>      "CodeDeployApplication",<br/>      "CodePipelinePipeline",<br/>      "CodeStarProject",<br/>      "CognitoIdentityPool",<br/>      "CognitoUserPool",<br/>      "CognitoUserPoolDomain",<br/>      "DAXCluster",<br/>      "DAXParameterGroup",<br/>      "DAXSubnetGroup",<br/>      "DataPipelinePipeline",<br/>      "DatabaseMigrationServiceCertificate",<br/>      "DatabaseMigrationServiceEndpoint",<br/>      "DatabaseMigrationServiceEventSubscription",<br/>      "DatabaseMigrationServiceReplicationInstance",<br/>      "DatabaseMigrationServiceReplicationTask",<br/>      "DatabaseMigrationServiceSubnetGroup",<br/>      "DeviceFarmProject",<br/>      "DirectoryServiceDirectory",<br/>      "DynamoDBTable",<br/>      "EC2Address",<br/>      "EC2ClientVpnEndpoint",<br/>      "EC2ClientVpnEndpointAttachment",<br/>      "EC2CustomerGateway",<br/>      "EC2Image",<br/>      "EC2Instance",<br/>      "EC2InternetGateway",<br/>      "EC2InternetGatewayAttachment",<br/>      "EC2KeyPair",<br/>      "EC2LaunchTemplate",<br/>      "EC2NATGateway",<br/>      "EC2NetworkACL",<br/>      "EC2PlacementGroup",<br/>      "EC2RouteTable",<br/>      "EC2SecurityGroup",<br/>      "EC2Snapshot",<br/>      "EC2SpotFleetRequest",<br/>      "EC2Subnet",<br/>      "EC2TGW",<br/>      "EC2TGWAttachment",<br/>      "EC2VPC",<br/>      "EC2VPCEndpoint",<br/>      "EC2VPCEndpointServiceConfiguration",<br/>      "EC2VPCPeeringConnection",<br/>      "EC2VPNConnection",<br/>      "EC2VPNGatewayAttachment",<br/>      "EC2Volume",<br/>      "ECRRepository",<br/>      "EFSFileSystem",<br/>      "EFSMountTarget",<br/>      "EKSCluster",<br/>      "ELB",<br/>      "ELBv2",<br/>      "ELBv2TargetGroup",<br/>      "EMRCluster",<br/>      "EMRSecurityConfiguration",<br/>      "ESDomain",<br/>      "ElasticBeanstalkApplication",<br/>      "ElasticBeanstalkEnvironment",<br/>      "ElasticTranscoderPipeline",<br/>      "ElasticacheCacheCluster",<br/>      "ElasticacheReplicationGroup",<br/>      "ElasticacheSubnetGroup",<br/>      "FSxBackup",<br/>      "FSxFileSystem",<br/>      "FirehoseDeliveryStream",<br/>      "GlueClassifier",<br/>      "GlueConnection",<br/>      "GlueCrawler",<br/>      "GlueDatabase",<br/>      "GlueDevEndpoint",<br/>      "GlueJob",<br/>      "GlueTrigger",<br/>      "IAMGroup",<br/>      "IAMGroupPolicy",<br/>      "IAMGroupPolicyAttachment",<br/>      "IAMInstanceProfile",<br/>      "IAMInstanceProfileRole",<br/>      "IAMLoginProfile",<br/>      "IAMOpenIDConnectProvider",<br/>      "IAMRole",<br/>      "IAMServerCertificate",<br/>      "IAMServiceSpecificCredential",<br/>      "IAMUser",<br/>      "IAMUserAccessKey",<br/>      "IAMUserGroupAttachment",<br/>      "IAMUserPolicy",<br/>      "IAMUserPolicyAttachment",<br/>      "IAMVirtualMFADevice",<br/>      "IoTAuthorizer",<br/>      "IoTCACertificate",<br/>      "IoTCertificate",<br/>      "IoTJob",<br/>      "IoTOTAUpdate",<br/>      "IoTPolicy",<br/>      "IoTRoleAlias",<br/>      "IoTStream",<br/>      "IoTThing",<br/>      "IoTThingGroup",<br/>      "IoTThingType",<br/>      "IoTThingTypeState",<br/>      "IoTTopicRule",<br/>      "KMSAlias",<br/>      "KMSKey",<br/>      "KinesisAnalyticsApplication",<br/>      "KinesisStream",<br/>      "KinesisVideoProject",<br/>      "LambdaEventSourceMapping",<br/>      "LambdaFunction",<br/>      "LaunchConfiguration",<br/>      "LifecycleHook",<br/>      "LightsailDisk",<br/>      "LightsailDomain",<br/>      "LightsailInstance",<br/>      "LightsailKeyPair",<br/>      "LightsailLoadBalancer",<br/>      "LightsailStaticIP",<br/>      "MQBroker",<br/>      "MSKCluster",<br/>      "MediaConvertJobTemplate",<br/>      "MediaConvertPreset",<br/>      "MediaConvertQueue",<br/>      "MediaLiveChannel",<br/>      "MediaLiveInput",<br/>      "MediaLiveInputSecurityGroup",<br/>      "MediaPackageChannel",<br/>      "MediaPackageOriginEndpoint",<br/>      "MediaStoreContainer",<br/>      "MediaStoreDataItems",<br/>      "MediaTailorConfiguration",<br/>      "MobileProject",<br/>      "NeptuneCluster",<br/>      "NeptuneInstance",<br/>      "NetpuneSnapshot",<br/>      "OpsWorksApp",<br/>      "OpsWorksCMBackup",<br/>      "OpsWorksCMServer",<br/>      "OpsWorksCMServerState",<br/>      "OpsWorksInstance",<br/>      "OpsWorksLayer",<br/>      "OpsWorksUserProfile",<br/>      "RDSDBCluster",<br/>      "RDSDBClusterParameterGroup",<br/>      "RDSDBParameterGroup",<br/>      "RDSDBSubnetGroup",<br/>      "RDSInstance",<br/>      "RDSSnapshot",<br/>      "RedshiftCluster",<br/>      "RedshiftParameterGroup",<br/>      "RedshiftSnapshot",<br/>      "RedshiftSubnetGroup",<br/>      "RekognitionCollection",<br/>      "ResourceGroupGroup",<br/>      "RoboMakerDeploymentJob",<br/>      "RoboMakerFleet",<br/>      "RoboMakerRobot",<br/>      "RoboMakerRobotApplication",<br/>      "RoboMakerSimulationApplication",<br/>      "RoboMakerSimulationJob",<br/>      "Route53HostedZone",<br/>      "Route53ResourceRecordSet",<br/>      "S3Bucket",<br/>      "S3MultipartUpload",<br/>      "S3Object",<br/>      "SESConfigurationSet",<br/>      "SESIdentity",<br/>      "SESReceiptFilter",<br/>      "SESReceiptRuleSet",<br/>      "SESTemplate",<br/>      "SFNStateMachine",<br/>      "SNSEndpoint",<br/>      "SNSPlatformApplication",<br/>      "SNSSubscription",<br/>      "SNSTopic",<br/>      "SQSQueue",<br/>      "SSMActivation",<br/>      "SSMAssociation",<br/>      "SSMDocument",<br/>      "SSMMaintenanceWindow",<br/>      "SSMParameter",<br/>      "SSMPatchBaseline",<br/>      "SSMResourceDataSync",<br/>      "SageMakerEndpoint",<br/>      "SageMakerEndpointConfig",<br/>      "SageMakerModel",<br/>      "SageMakerNotebookInstance",<br/>      "SageMakerNotebookInstanceState",<br/>      "SecretsManagerSecret",<br/>      "ServiceCatalogConstraintPortfolioAttachment",<br/>      "ServiceCatalogPortfolio",<br/>      "ServiceCatalogPortfolioProductAttachment",<br/>      "ServiceCatalogPortfolioShareAttachment",<br/>      "ServiceCatalogPrincipalPortfolioAttachment",<br/>      "ServiceCatalogProduct",<br/>      "ServiceCatalogProvisionedProduct",<br/>      "ServiceCatalogTagOption",<br/>      "ServiceCatalogTagOptionPortfolioAttachment",<br/>      "ServiceDiscoveryInstance",<br/>      "ServiceDiscoveryNamespace",<br/>      "ServiceDiscoveryService",<br/>      "SimpleDBDomain",<br/>      "StorageGatewayFileShare",<br/>      "StorageGatewayGateway",<br/>      "StorageGatewayTape",<br/>      "StorageGatewayVolume",<br/>      "WAFRegionalByteMatchSet",<br/>      "WAFRegionalByteMatchSetIP",<br/>      "WAFRegionalIPSet",<br/>      "WAFRegionalIPSetIP",<br/>      "WAFRegionalRateBasedRule",<br/>      "WAFRegionalRateBasedRulePredicate",<br/>      "WAFRegionalRegexMatchSet",<br/>      "WAFRegionalRegexMatchTuple",<br/>      "WAFRegionalRegexPatternSet",<br/>      "WAFRegionalRegexPatternString",<br/>      "WAFRegionalRule",<br/>      "WAFRegionalRulePredicate",<br/>      "WAFRegionalWebACL",<br/>      "WAFRegionalWebACLRuleAttachment",<br/>      "WAFRule",<br/>      "WAFWebACL",<br/>      "WAFWebACLRuleAttachment",<br/>      "WorkLinkFleet",<br/>      "WorkSpacesWorkspace",<br/>    ])<br/>    # A collection of resources to include in the nuke <br/>  })</pre> | `{}` | no |
| <a name="input_presets"></a> [presets](#input\_presets) | A collection of presets used in the nuke | <pre>map(map(list(object({<br/>    property = string<br/>    type     = string<br/>    value    = string<br/>  }))))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configuration"></a> [configuration](#output\_configuration) | The rendered configuration file for the nuke service |
<!-- END_TF_DOCS -->