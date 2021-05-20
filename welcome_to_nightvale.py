# The main script to drive the project with gorbachev
from runner import trigger_job, load_parameters
from utils import initialise_logger

global logger
logger = initialise_logger('INFO', __file__)

params = load_parameters('parameters.yaml')

trigger_job('welcome-to-nightvale',    requires = [],          params = params)
