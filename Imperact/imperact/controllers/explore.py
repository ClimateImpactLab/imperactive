# -*- coding: utf-8 -*-
"""Explore controller module"""

import os
from tg import expose, redirect, validate, flash, url

from imperact.lib.base import BaseController
from imperact.lib.errors import UserException

directory_root = '/shares/gcp/outputs'

class ExploreController(BaseController):
    @expose('imperact.templates.explore.outputs')
    def index(self, **kw):
        return dict(subdir=kw.get('subdir', ''))

    @expose('json')
    def list_subdir(self, subdir):
        return dict(contents=os.path.listdir(os.path.join(directory_root, subdir)))

    @expose()
    def timeseries(self, targetdir, basename, variable, region):
        target = os.path.join(targetdir, "%s.%s.%s.nc4" % (basename, variable, region))
        if not os.path.exists(target) or os.path.time(target) < os.path.time(os.path.join(targetdir, basename + '.nc4')):
            os.system("Rscript plot-timeseries.R %s %s %s %s" % (targetdir, basename, variable, region))

        return download(target)

    @expose(content_type='image/png')
    def download_png(self, subpath):
        if '..' in subpath or '//' in subpath:
            raise UserException("Unexpected path.")
        with open(os.path.join(directory_root, 'r')) as fp:
            return fp.read()
        
