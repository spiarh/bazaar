<?php
if (getenv('S3_ACCESS_KEY_ID') && getenv('S3_SECRET_ACCESS_KEY') && getenv('S3_ENDPOINT') && getenv('S3_REGION')) {
  $CONFIG = array (
    'objectstore' => array(
      'class' => '\\OC\\Files\\ObjectStore\\S3',
      'arguments' => array(
        'bucket' => getenv('S3_BUCKET') ?: 'nextcloud',
        'autocreate' => true,
        'key'    => getenv('S3_ACCESS_KEY_ID'),
        'secret' => getenv('S3_SECRET_ACCESS_KEY'),
        'hostname' => getenv('S3_ENDPOINT'),
        'port' => getenv('S3_ENDPOINT_PORT') ?: 443,
        'use_ssl' => true,
        'region' => getenv('S3_REGION'),
        'use_path_style'=>true
      ),
    ),
  );
}
