#!/usr/bin/env python

import os
os.environ.setdefault('SCRAPY_SETTINGS_MODULE', 'lasexta.settings')

from scrapy.command.cmdline import execute
execute()
