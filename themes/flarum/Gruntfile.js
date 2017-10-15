module.exports = function(grunt) {

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        less: {
            options: {
                compress: true,
                yuicompress: true,
                optimization: 3
            },
            files: {
                src : "css/sami.less",
                dest : "css/sami.css"
            }
        },
        watch: {
            scripts: {
                files: [
                    'js/*.js',
                    'css/**/*.less',
                    '!js/<%= pkg.name %>.js',
                    '!js/<%= pkg.name %>.min.js'
                ],
                tasks: ['less', 'jshint', 'concat','uglify', 'imagemin'],
                options: {
                    event: ['added', 'deleted', 'changed']
                },
            },
        }
    });

    /*
     * Watch differently LESS and JS
     */
    grunt.event.on('watch', function(action, filepath) {
        if(filepath.indexOf('.less') > -1 ){
            grunt.config('watch.scripts.tasks', ['less']);
        }
    });

    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-contrib-less');

    // Default task(s).
    grunt.registerTask('default', ['less']);
};