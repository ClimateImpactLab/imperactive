# -*- coding: utf-8 -*-
"""Explore controller module"""

from tg import expose, redirect, validate, flash, url
# from tg.i18n import ugettext as _
# from tg import predicates

from imperact.lib.base import BaseController
# from imperact.model import DBSession


class ExploreController(BaseController):
    # Uncomment this line if your controller requires an authenticated user
    # allow_only = predicates.not_anonymous()
    
    @expose('imperact.templates.explore')
    def index(self, **kw):
        return dict(page='explore-index')
