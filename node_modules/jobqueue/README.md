# Job Queue

Work in progress. The API should look like:

    queue.register { step: 'postproc' },
      # attributes that comprise the job ID; requests with identical IDs are merged into a single job
      id: ['project', 'step']

      # merge oldRequest into newRequest; by default, all array attributes are merged;
      # ID attributes are guaranteed to be equal
      merge: (newRequest, oldRequest) ->

      execute: (request, emit) ->
        @add type: 'warning', file: '/foo'
        @done null

    queue.add { project: @project.id, step: 'postproc', paths: paths }

    # value triggering (remove existing jobs with this scope, then add new ones)
    queue.update { project: @project.id, step: 'postproc' }, { paths: [paths] }
    queue.update { project: @project.id, step: 'compile' }, [{src: '/path/to/src'}, {src: '/another/src'}]

    queue.cancel { project: @project.id }


Work in progress.

## License

Copyright 2012, Andrey Tarantsov. Distributed under the MIT license.
