# -*- coding: utf-8 -*-
"""Explore controller module"""

import os, yaml
from tg import expose, redirect, validate, flash, url, response

debug = False
if debug:
    from imperact.lib.base import BaseController
    from imperact.lib.errors import UserException
    template_root = 'imperact'
    CUSTOM_CONTENT_TYPE = 'image/png'
else:
    from aggregator.lib.base import BaseController
    from aggregator.lib.errors import UserException
    template_root = 'aggregator'
    from tg.controllers import CUSTOM_CONTENT_TYPE

directory_root = '/shares/gcp/outputs'
scripts_root = '/home/jrising/research/gcp/imperactive/scripts'

class ExploreController(BaseController):
    @expose(template_root + '.templates.explore.outputs')
    def index(self, **kw):
        return dict(subdir=kw.get('subdir', ''))

    @expose('json')
    def list_subdir(self, subdir=''):
        if subdir == '':
            fullpath = directory_root
        else:
            fullpath = os.path.join(directory_root, subdir)

        contents = {}
        for content in os.listdir(fullpath):
            if os.path.isdir(os.path.join(fullpath, content)):
                if os.path.exists(os.path.join(fullpath, content, "about.yml")):
                    with open(os.path.join(fullpath, content, "about.yml"), 'r') as fp:
                        about = yaml.load(fp)
                    contents[content] = about
                else:
                    contents[content] = None
            else:
                contents[content] = None
            
        return dict(contents=contents)

    @expose()
    def timeseries(self, targetdir, basename, variable, region):
        target = os.path.join(directory_root, targetdir, 'cache', "%s.%s.%s.png" % (basename, variable, region))
        if not os.path.exists(target) or os.path.getmtime(target) < os.path.getmtime(os.path.join(directory_root, targetdir, basename + '.nc4')):
            script = os.path.join(scripts_root, 'plot-timeseries.R')
            os.system("Rscript %s %s %s %s \"%s\"" % (script, targetdir, basename, variable, region))

        return self.download_png(target)

    @expose(content_type=CUSTOM_CONTENT_TYPE)
    def download_png(self, subpath):
        if '..' in subpath or '//' in subpath:
            raise UserException("Unexpected path.")

        with open(os.path.join(directory_root, subpath), 'r') as fp:
            data = fp.read()

        response.content_type = 'image/png'
        response.headerlist.append(('Content-Disposition','filename=export.png'))

        return data

