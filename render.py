import sys
import numpy as np
from OpenGL.GL import *
from OpenGL.GLUT import *
from OpenGL.GLU import *
from PIL import Image
import os
import traceback

# Load shader from myshader.glsl
try:
    with open("myshader.glsl", "r") as file:
        shader_body = file.read()
except FileNotFoundError:
    print("Error: myshader.glsl not found in current directory")
    sys.exit(1)

# Append uniforms and main function to make it a valid fragment shader
fragment_shader_code = f"""
#version 330 core
out vec4 FragColor;
uniform vec2 iResolution;
uniform float iTime;
{shader_body}
void main() {{
    mainImage(FragColor, gl_FragCoord.xy);
}}
"""

# Window settings
width, height = 1080, 1080  # Desired resolution
duration = 6.28318530718  # Video duration in seconds
fps = 120  # Frames per second
total_frames = int(duration * fps)

# Initialize OpenGL
def init_opengl():
    try:
        glutInit(sys.argv)
        glutInitContextVersion(3, 3)  # Request OpenGL 3.3
        glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE)
        glutInitWindowSize(width, height)
        glutCreateWindow(b"Shadertoy Render")
        glClearColor(0.0, 0.0, 0.0, 1.0)

        # Create and compile shader
        shader_program = glCreateProgram()
        fragment_shader = glCreateShader(GL_FRAGMENT_SHADER)
        glShaderSource(fragment_shader, fragment_shader_code)
        glCompileShader(fragment_shader)
        
        if not glGetShaderiv(fragment_shader, GL_COMPILE_STATUS):
            print(f"Shader compilation error: {glGetShaderInfoLog(fragment_shader).decode()}")
            sys.exit(1)
        
        glAttachShader(shader_program, fragment_shader)
        glLinkProgram(shader_program)
        
        if not glGetProgramiv(shader_program, GL_LINK_STATUS):
            print(f"Program linkage error: {glGetProgramInfoLog(shader_program).decode()}")
            sys.exit(1)
        
        glUseProgram(shader_program)
        
        return shader_program
    except Exception as e:
        print(f"OpenGL initialization error: {str(e)}")
        traceback.print_exc()
        sys.exit(1)

# Render and save frame
def render_frame(frame, shader_program):
    try:
        glClear(GL_COLOR_BUFFER_BIT)
        
        # Set Shadertoy uniforms
        iTime = frame / fps
        loc_resolution = glGetUniformLocation(shader_program, "iResolution")
        loc_time = glGetUniformLocation(shader_program, "iTime")
        if loc_resolution == -1 or loc_time == -1:
            print(f"Error: Uniforms not found (iResolution: {loc_resolution}, iTime: {loc_time})")
            sys.exit(1)
        glUniform2f(loc_resolution, width, height)
        glUniform1f(loc_time, iTime)
        
        # Render full-screen quad
        glBegin(GL_QUADS)
        glVertex2f(-1, -1)
        glVertex2f(1, -1)
        glVertex2f(1, 1)
        glVertex2f(-1, 1)
        glEnd()
        
        # Swap buffers
        glutSwapBuffers()
        
        # Read pixels and save as PNG
        pixels = glReadPixels(0, 0, width, height, GL_RGB, GL_UNSIGNED_BYTE)
        if not pixels:
            print(f"Error: Failed to read pixels for frame {frame}")
            return
        image = Image.frombytes("RGB", (width, height), pixels)
        image = image.transpose(Image.Transpose.FLIP_TOP_BOTTOM)  # Corrected for newer Pillow versions
        frame_path = f"frames/frame_{frame:04d}.png"
        image.save(frame_path)
        print(f"Saved frame {frame + 1}/{total_frames} to {frame_path}")
    except Exception as e:
        print(f"Error rendering frame {frame}: {str(e)}")
        traceback.print_exc()

def main():
    # Create output directory
    os.makedirs("frames", exist_ok=True)
    
    # Initialize OpenGL
    shader_program = init_opengl()
    
    # Dummy display function to suppress freeglut warning
    def display():
        pass
    glutDisplayFunc(display)
    
    # Render each frame
    for frame in range(total_frames):
        render_frame(frame, shader_program)
        glutMainLoopEvent()  # Process GLUT events
        if not os.path.exists(f"frames/frame_{frame:04d}.png"):
            print(f"Warning: Frame {frame + 1} was not saved")
    
    # Clean up
    glDeleteProgram(shader_program)
    glutDestroyWindow(glutGetWindow())

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Main loop error: {str(e)}")
        traceback.print_exc()
        sys.exit(1)