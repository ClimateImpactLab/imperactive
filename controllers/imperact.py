# -*- coding: utf-8 -*-
"""Now controller."""

import os
from tg import abort, expose, request

from aggregator.lib.base import BaseController
from aggregator.lib.errors import UserException

__all__ = ['ImperactController']

directory_root = '/shares/gcp/outputs'

class ImperactController(BaseController):
    @expose('aggregator.templates.imperact.explore')
    def explore(self, subdir=''):
        return dict(subdir=subdir)

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
        
