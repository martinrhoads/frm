DEFAULT_HOST =  's3-us-west-1.amazonaws.com' # stupid hack to point to the right s3 region

require 'zlib'
require 'tempfile'
require 'digest/md5'
require 'digest/sha1'
require 'digest/sha2'

require 'frm/base'
require 'frm/s3'
require 'frm/package'
require 'frm/release'
require 'frm/release_pusher'
require 'frm/deb'

