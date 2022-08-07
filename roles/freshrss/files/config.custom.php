<?php

// See more options at https://github.com/FreshRSS/FreshRSS/blob/edge/config.default.php
return array(
  'auth_type' => 'http_auth',
  'trusted_sources' => [
    // Trust docker networks
    "172.100.0.0/8"
  ],
);