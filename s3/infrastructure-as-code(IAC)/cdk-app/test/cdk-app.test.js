const cdk = require('aws-cdk-lib/core');
const { Template } = require('aws-cdk-lib/assertions');
const { CdkAppStack } = require('../lib/cdk-app-stack');

test('S3 Bucket Created', () => {
  const app = new cdk.App();
  // WHEN
  const stack = new CdkAppStack(app, 'MyTestStack');
  // THEN
  const template = Template.fromStack(stack);

  template.resourceCountIs('AWS::S3::Bucket', 1);
  template.hasResourceProperties('AWS::S3::Bucket', {
    BucketEncryption: {
      ServerSideEncryptionConfiguration: [
        { ServerSideEncryptionByDefault: { SSEAlgorithm: 'AES256' } },
      ],
    },
    PublicAccessBlockConfiguration: {
      BlockPublicAcls: true,
      BlockPublicPolicy: true,
      IgnorePublicAcls: true,
      RestrictPublicBuckets: true,
    },
  });
});
