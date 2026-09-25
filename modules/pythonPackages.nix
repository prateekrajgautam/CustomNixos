{ config, pkgs, lib, ... }:

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        python3
        pipenv
      ] ++ (with python3Packages; [
        pip
        django
        fastapi
        uvicorn
        sqlmodel
        numpy
        pandas
        openpyxl
        jupyterlab
        matplotlib
        playwright
        scipy
        librosa
        soundfile
        tqdm
#        venv
#        jinja2
#        pyinstaller
      ]);
    };
  };
}

