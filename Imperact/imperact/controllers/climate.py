# -*- coding: utf-8 -*-
"""Climate controller module"""

from tg import expose, redirect, validate, flash, url
# from tg.i18n import ugettext as _
# from tg import predicates

try:
    from . import debug
except:
    debug = False
if debug:
    from imperact.lib.base import BaseController
    template_root = 'imperact'
    import imperact as aggregator
else:
    from aggregator.lib.base import BaseController
    template_root = 'aggregator'
    import aggregator

import os, re, json

directory_root = '/shares/gcp/climate'
ignores = ['climate_data_aggregation', 'BCSD/SMME-europe-zipped', '_spatial_data', 'ACP', 'SPEI', 'CFSR', 'CRUNCEP', 'CHIRPS']
RE_GCM = r'ACCESS1-0|bcc-csm1-1|BNU-ESM|CanESM2|CCSM4|CESM1-BGC|CNRM-CM5|CSIRO-Mk3-6-0|GFDL-CM3|GFDL-ESM2G|GFDL-ESM2M|inmcm4|IPSL-CM5A-LR|IPSL-CM5A-MR|MIROC5|MIROC-ESM|MIROC-ESM-CHEM|MPI-ESM-LR|MPI-ESM-MR|MRI-CGCM3|NorESM1-M|pattern[0-9]{1,2}|bcc-csm1-1-m|fgoals-g2|hadgem2-cc|hadgem2-ao|hadgem2-es|ipsl-cm5b-lr|hadcm3|cmcc-cm|giss-e2-r|fio-esm|giss-e2-h-cc|cesm1-cam5|giss-e2-r-cc|access1-3|giss-e2-r-cc|noresm1-me'
RE_RCP = r'rcp[024568]{2}|historical'
reco_gcm = re.compile(r'/(' + RE_GCM + ')(/.*)?$', re.IGNORECASE)
reco_rcp = re.compile(r'/(' + RE_RCP + ')(/.*)?$', re.IGNORECASE)
reco_year = re.compile(r"[12]\d{3}$")
reco_version = re.compile(r"\d\.\d\.[ncfgh4]+")
reco_daily = re.compile(r"[12]\d{3}\.[nc4]+")
reco_yearly = re.compile(r"_aggregated?_(rcp[024568]{2}|historical)_r1i1p1_[a-zA-Z0-9-]+.nc4?")
reco_pattern = re.compile(r"([-_])([12]\d{3})([-_.])")

def re_sub(pattern, replacement, string):
    def _r(m):
        # Now this is ugly.
        # Python has a "feature" where unmatched groups return None
        # then re.sub chokes on this.
        # see http://bugs.python.org/issue1519638

        # this works around and hooks into the internal of the re module...

        # the match object is replaced with a wrapper that
        # returns "" instead of None for unmatched groups

        class _m():
            def __init__(self, m):
                self.m=m
                self.string=m.string
            def group(self, n):
                return m.group(n) or ""

        return re._expand(pattern, _m(m), replacement)

    if isinstance(pattern, str):
        return re.sub(pattern, _r, string)
    else:
        return pattern.sub(_r, string)

class ClimateController(BaseController):
    # Uncomment this line if your controller requires an authenticated user
    # allow_only = predicates.not_anonymous()
    
    @expose(template_root + '.templates.explore.climate')
    def index(self, **kw):
        print "OK"
        return dict(page='climate-index')

    @expose()
    def refresh_listing(self):
        data = self.listing()
        with open(os.path.join(aggregator.__path__[0], 'public', 'climate-listing.json'), 'w') as fp:
            json.dump(data, fp)
        return "DONE"

    @expose('json')
    def listing(self, basedir=''):
        items = {} # {path: information}
        basedirpath = os.path.join(directory_root, basedir)

        for content in os.listdir(basedirpath):
            if content[0] == '.':
                continue # skip hidden dirs
            if content in ['@eaDir', 'gridded', 'formatting', 'download', 'raw_data']:
                continue # skip pre-formatted
            fullpath = os.path.join(basedirpath, content)
            if fullpath[len(directory_root)+1:] in ignores:
                continue
            
            if os.path.isdir(fullpath):
                newitems = self.interpret_directory(fullpath)
                if newitems:
                    items.update(newitems)
                else:
                    items.update(self.listing(os.path.join(basedir, content)))
            else:
                information = self.interpret_file(fullpath)
                if information:
                    items[self.clean_path(os.path.join(basedir, content))] = information

        with open(os.path.join(aggregator.__path__[0], 'public', 'climate-listing-custom.json'), 'r') as fp:
            items.update(json.load(fp))

        return items

    def clean_path(self, path):
        path = re_sub(reco_gcm, r'/%g\2', path)
        path = re_sub(reco_rcp, r'/%r\2', path)
        return path
    
    def interpret_file(self, filepath):
        if os.path.splitext(filepath)[1] in ['.nc', '.nc4']:
            return dict(type="single")

    def interpret_directory(self, fullpath):
        filenames = os.listdir(fullpath)
        if len(filenames) == 0:
            return None
        
        if len(filenames) == 1:
            information = self.interpret_file(os.path.join(fullpath, filenames[0]))
            if information:
                fullpath = self.clean_path(fullpath)
                return {fullpath[len(directory_root) + 1:]: information}

        guesses = set()
        patterns = set()
        for filename in filenames:
            filepath = os.path.join(fullpath, filename)
            if os.path.isdir(filepath):
                if reco_year.match(filename):
                    guesses.add("versioned")
                else:
                    return None # Not a leaf
            elif reco_version.match(filename):
                guesses.add("versioned")
            elif reco_daily.match(filename):
                guesses.add("daily")
            elif reco_yearly.search(filename):
                guesses.add("yearly")
            elif reco_pattern.search(filename):
                patterns.add(reco_pattern.sub("\1%y\3", filename))
                guesses.add("pattern")

        # Replace any model directories with %g
        fullpath = self.clean_path(fullpath)
        if len(guesses) == 1:
            return {fullpath[len(directory_root) + 1:]: dict(type=guesses.pop())}
        else:
            print fullpath, guesses
            return {fullpath[len(directory_root) + 1:]: dict(type="ambiguous")}

