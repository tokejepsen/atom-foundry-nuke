fs   = require 'fs'
path = require 'path'
sys  = require 'sys'
exec = require('child_process').exec
StatusView = require './status-view'
temp = require 'temp'
{CompositeDisposable} = require 'atom'
{MessagePanelView, PlainMessageView} = require 'atom-message-panel'

module.exports =

    modalTimeout: null
    messagepanel: null

    activate: (state) ->

      atom.commands.add 'atom-workspace', "nuke:closeMessage", => @closeMessage()

      # Set defaults
      atom.config.setDefaults("nuke", host: '127.0.0.1', port: 8888, save_on_run: true )

      # Create the status view
      @statusView = new StatusView(state.statusViewState)
      @modalPanel = atom.workspace.addModalPanel(item: @statusView.getElement(), visible: false)

      # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
      @subscriptions = new CompositeDisposable

      # Listen for run command
      @subscriptions.add atom.commands.add 'atom-workspace', 'nuke:run': => @run()

      # Automatically track and cleanup files at exit
      temp.track()


    deactivate: ->
        @statusView.destroy()
        @subscriptions.dispose()

    serialize: ->

    getActiveEditor: ->
        atom.workspace.getActiveTextEditor()

    run: ->

        # Get the current selection
        editor = @getActiveEditor()

        if atom.config.get('nuke').save_on_run
          editor.save()

        selection = editor.getLastSelection()

        if editor.getLastSelection().isEmpty()
            # Get the active pane file path
            @send_to_nuke editor.buffer.file.path
        else
            # console.log('send selection', selection)
            # Create a tmp file and save the selection
            text = editor.getSelections()[0].getText()

            @get_tmp_file_for_selection text, (file) =>
               @send_to_nuke file

        return

    send_to_nuke: (file) ->

        # console.log('send to nuke', file)

        if not file.match '.py'
            @updateStatusView "Error: Not a python file"
            @closeModal()
            return

        HOST = atom.config.get('nuke').host
        PORT = atom.config.get('nuke').port

        cmd  = "python #{__dirname}/send_to_nuke.py"
        cmd += " -f \"#{file}\""
        cmd += " -a '#{HOST}'" #h results in a conflict?
        cmd += " -p #{PORT}"

        date = new Date()

        @updateStatusView "Executing file: #{file}"

        exec cmd, (error, stdout, stderr) =>

            console.log 'stdout', stdout
            console.log 'stderr', stderr

            @messagepanel = new MessagePanelView({title: 'Nuke Feedback'}) unless @messagepanel?

            @messagepanel.clear()
            @messagepanel.attach()

            String::startsWith ?= (s) -> @slice(0, s.length) == s

            lines = stdout.split('\n')
            text_class = 'text-highlight'
            for line in lines
              text_class = 'text-error' if line.startsWith('Traceback (most recent call last):')

              @messagepanel.add new PlainMessageView
                message: line
                className: text_class

            ellapsed = (Date.now() - date) / 1000

            if error?
                @updateStatusView "Error: #{stderr}"
                console.error 'error', error
            else
                @updateStatusView "Success: Ran in #{ellapsed}s"

            # Cleanup any tmp files created
            temp.cleanup()

            @closeModal()

    updateStatusView: (text) ->

        clearTimeout @modalTimeout

        @modalPanel.show()
        @statusView.update "[atom-foundry-nuke] #{text}"

    closeMessage: ->

      try @messagepanel.close()

    closeModal: ->

      clearTimeout @modalTimeout

      @modalTimeout = setTimeout =>
        @modalPanel.hide()
      , 2000

    get_tmp_file_for_selection: (selection, callback) ->

        temp.mkdir 'atom-foundry-nuke-selection', (err, dirPath) ->

            inputPath = path.join dirPath, 'command.py'

            fs.writeFile inputPath, selection, (err) ->

                if err?
                    throw err
                else
                    callback inputPath
