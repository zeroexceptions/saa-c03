const { Stack, RemovalPolicy } = require('aws-cdk-lib/core');
const s3 = require('aws-cdk-lib/aws-s3');

class CdkAppStack extends Stack {
  /**
   *
   * @param {Construct} scope
   * @param {string} id
   * @param {StackProps=} props
   */
  constructor(scope, id, props) {
    super(scope, id, props);

    // S3 bucket with sensible defaults: encrypted, no public access.
    // RemovalPolicy.DESTROY + autoDeleteObjects is only for practice/learning stacks
    // so `cdk destroy` doesn't leave an orphaned bucket behind.
    const bucket = new s3.Bucket(this, 'CdkAppBucket', {
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    this.bucket = bucket;
  }
}

module.exports = { CdkAppStack }
