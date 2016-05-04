path                = require 'path'
fs                  = require 'fs'
HOMEDIR             = path.join __dirname, '..'
IS_INSTRUMENTED     = fs.existsSync(path.join(HOMEDIR,'lib-cov'))
LIB_DIR             = if IS_INSTRUMENTED then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
should              = require 'should'
DustEngine          = require(path.join(LIB_DIR,'dust-engine')).DustEngine

describe 'DustEngine',->

  it "exists", (done)=>
    should.exist DustEngine
    done()

  it "can be initialized", (done)=>
    de = new DustEngine()
    should.exist(de)
    should.exist(de.render_for_express)
    done()
