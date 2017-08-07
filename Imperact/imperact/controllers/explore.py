# -*- coding: utf-8 -*-
"""Explore controller module"""

import os, yaml, subprocess, datetime, time
from tg import expose, redirect, validate, flash, url, response
import numpy as np

debug = False
if debug:
    from imperact.lib.base import BaseController
    from imperact.lib.errors import UserException
    template_root = 'imperact'
    CUSTOM_CONTENT_TYPE = 'image/png'
    import imperact as aggregator
else:
    from aggregator.lib.base import BaseController
    from aggregator.lib.errors import UserException
    template_root = 'aggregator'
    from tg.controllers import CUSTOM_CONTENT_TYPE
    import aggregator

directory_root = '/shares/gcp/outputs'
scripts_root = '/home/jrising/research/gcp/imperactive/scripts'
last_purge = time.mktime(datetime.datetime(2017, 7, 20, 0, 0, 0).timetuple())

hierarchy = metacsv.read_csv("/shares/gcp/regions/hierarchy_metacsv.csv")

irlevel_keys = np.concatenate((hierarchy['region-key'][hierarchy['is_terminal']], hierarchy['region-key'][hierarchy['is_terminal']], hierarchy['region-key'][(hierarchy['alternatives'].astype('S') != 'nan') & (hierarchy['is_terminal'])])).astype('S')
irlevel_labels = np.concatenate((hierarchy['region-key'][hierarchy['is_terminal']], hierarchy['name'][hierarchy['is_terminal']], hierarchy['alternatives'][(hierarchy['alternatives'].astype('S') != 'nan') & (hierarchy['is_terminal'])])).astype('S')
irlevel_search = np.core.defchararray.lower(irlevel_labels)

aggregated_keys = np.concatenate((['', ''], hierarchy['region-key'][np.logical_not(hierarchy['is_terminal'])], hierarchy['region-key'][np.logical_not(hierarchy['is_terminal'])], hierarchy['region-key'][(hierarchy['alternatives'].astype('S') != 'nan') & (np.logical_not(hierarchy['is_terminal']))])).astype('S')
aggregated_labels = np.concatenate((['Global', 'World'], hierarchy['region-key'][np.logical_not(hierarchy['is_terminal'])], hierarchy['name'][np.logical_not(hierarchy['is_terminal'])], hierarchy['alternatives'][(hierarchy['alternatives'].astype('S') != 'nan') & (np.logical_not(hierarchy['is_terminal']))])).astype('S')
aggregated_search = np.core.defchararray.lower(aggregated_labels)

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

    @expose('json')
    def walk_subdir(self, subdir):
        fullpath = os.path.join(directory_root, subdir)

        contents = {} # {filename: #}
        for root, dirs, files in os.walk(fullpath):
            for content in files:
                contents[content] = contents.get(content, 0) + 1

        return dict(contents=contents)
    
    def graph_serve(self, targetdir, basenames, filename, generate):
        """Serve a graph, using cached if possible and otherwise calling generate."""
        outdir = os.path.join(aggregator.__path__[0], 'impercache', targetdir)
        destination = os.path.join(outdir, filename)
        if os.path.exists(destination):
            later_than_all = True
            for basename in basenames:
                if os.path.getmtime(destination) < last_purge:
                    later_than_all = False
                    break
                
                if os.path.getmtime(destination) < os.path.getmtime(os.path.join(directory_root, targetdir, basename + '.nc4')):
                    later_than_all = False
                    break

            if later_than_all:
                return self.download_png(destination)


        if not os.path.exists(outdir):
            os.makedirs(outdir)
        generate(destination)
        return self.download_png(destination)

    def make_r_generate(self, scriptname, arguments):
        """Create a generate function to pass to graph_serve that calls an R script."""
        def generate(destination):
            script = os.path.join(scripts_root, scriptname)
            try:
                return subprocess.check_output(["Rscript", script, destination] + arguments, stderr=subprocess.STDOUT)
            except subprocess.CalledProcessError as e:
                raise UserException("Command '{}' return with error (code {}): {}".format(e.cmd, e.returncode, e.output))

        return generate
    
    @expose()
    def timeseries(self, targetdir, basename, variable, region):
        calculation = [basename + ':' + variable]
        return self.graph_serve(targetdir, [basename], "%s.%s.%s.png" % (basename, variable, region),
                                self.make_r_generate('plot-timeseries.R', [targetdir, region] + calculation))

    @expose()
    def timeseries_sum(self, targetdir, basevars, region):
        calculation = basevars.split(',')
        basenames = map(lambda x: x[:x.index(':')], calculation)
        return self.graph_serve(targetdir, basenames, "%s.%s.png" % (basevars, region),
                                self.make_r_generate('plot-timeseries.R', [targetdir, region] + calculation))

    @expose('json')
    def search_regions(basename, query):
        if '-aggregated' in basename:
            founds = np.core.defchararray.find(aggregated_search, query.lower()) >= 0
            return dict(options=zip(aggregated_keys[founds], aggregated_labels[founds]))
        else:
            founds = np.core.defchararray.find(irlevel_search, query.lower()) >= 0
            return dict(options=zip(irlevel_keys[founds], irlevel_labels[founds]))
    
    @expose(content_type=CUSTOM_CONTENT_TYPE)
    def download_png(self, subpath):
        if '..' in subpath or '//' in subpath:
            raise UserException("Unexpected path.")

        with open(os.path.join(directory_root, subpath), 'r') as fp:
            data = fp.read()

        response.content_type = 'image/png'
        response.headerlist.append(('Content-Disposition','filename=export.png'))

        return data

