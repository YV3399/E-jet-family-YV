include('eventSource.nas');

var DownloadManager = {
    Job: {
        new: func (url, path) {
            return {
                parents: [me],
                url: url,
                path: path,
                tmpPath: path ~ '~tmp',
                onSuccess: EventSource.new(),
                onFailure: EventSource.new(),
                status: 'initial',
                error: nil,
                request: nil,
            };
        },

        send: func {
            me.status = 'running';
            me.request =
                http.save(me.url, me.path)
                    .done(func {
                        # Request succeeded
                        logprint(2, sprintf("HTTP OK %s", me.url));

                        # Move temporary file into final location.
                        os.path.new(me.tmpPath).rename(me.path);

                        me.status = 'finished';
                        me.onSuccess.raise(me.path);
                    })
                    .fail(func (r) {
                        # Request aborted or failed
                        logprint(3, sprintf("HTTP %i %s (%s)", r.status, me.url, r.reason));

                        # Remove temporary file - if it exists, it will be
                        # incomplete, and thus useless.
                        os.path.new(me.tmpPath).remove();

                        if (me.status != 'aborted') {
                            # If request was already aborted, don't re-report.
                            me.status = 'failed';
                            me.error = r;
                            me.onFailure.raise(r);
                        }
                    });
        },

        cancel: func (hard=1) {
            logprint(2, sprintf("CANCEL %s (%s)", me.url, hard ? "hard" : "soft"));
            if (me.status == 'finished' or me.status == 'failed') {
                # Already done, can't cancel anymore
                return;
            }
            me.onSuccess.removeAllListeners();
            if (hard) {
                if (me.request != nil)
                    me.request.abort();
                me.status = 'aborted';
                me.request = nil;
            }
            else {
                me.onFailure.raise({status: -1, reason: 'Request cancelled'});
                me.onFailure.removeAllListeners();
            }
        },

    },

    new: func {
        return {
            parents: [me],
            cacheBase: getprop("/sim/fg-home") ~ '/cache/',
            jobs: {},
        };
    },

    # Cancel all in-flight requests. 
    cancel: func (url, hard=1) {
        if (contains(me.jobs, url)) {
            me.jobs[url].cancel(hard);
        }
    },

    cancelAll: func () {
        foreach (var job; values(me.jobs)) {
            job.cancel(1);
        }
        me.jobs = {};
    },

    get: func (url, path, onSuccess, onFailure, replace=0) {
        var actualPath = me.cacheBase ~ path;
        logprint(2, sprintf("GET %s -> %s; actual: %s", url, path, actualPath));
        if (contains(me.jobs, url) and me.jobs[url] != nil) {
            var job = me.jobs[url];
            # debug.dump(job);
            if (job.status == 'finished') {
                # Already finished: no need to add listener, just trigger
                # success handler directly.
                onSuccess(actualPath);
            }
            elsif (job.status == 'running') {
                if (replace) {
                    job.onSuccess.removeAllListeners();
                }
                job.onSuccess.addListener(onSuccess);
            }
            elsif (job.status == 'failed') {
                # Already failed: no need to add listener, just error
                # success handler directly.
                onFailure(job.error);
            }
            elsif (job.status == 'canceled') {
                # re-send
                job.onSuccess.addListener(onSuccess);
                job.onFailure.addListener(onFailure);
                job.send();
            }
        }
        elsif (io.stat(me.cacheBase ~ path) != nil) {
            logprint(2, sprintf("CACHE GET %s", url));
            onSuccess(actualPath);
        }
        else {
            logprint(2, sprintf("HTTP GET %s", url));
            me.jobs[url] = me.Job.new(url, actualPath);
            me.jobs[url].onSuccess.addListener(onSuccess);
            me.jobs[url].onFailure.addListener(onFailure);
            me.jobs[url].send();
        }
    },
};
