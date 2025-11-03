#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <fstream>
#include <string>
#include <chrono>
#include <thread>
#include <filesystem>

// Function to read file content
std::string readFile(const std::string& path) {
    std::ifstream file(path);
    if (!file) {
        std::cerr << "Failed to open file: " << path << std::endl;
        return "";
    }
    std::string content((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
    std::cerr << "Loaded " << path << " (" << content.size() << " bytes)" << std::endl;
    return content;
}

// Compile shader
GLuint compileShader(GLenum type, const std::string& source) {
    GLuint shader = glCreateShader(type);
    const char* src = source.c_str();
    glShaderSource(shader, 1, &src, nullptr);
    glCompileShader(shader);
    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (!status) {
        char log[512];
        glGetShaderInfoLog(shader, 512, nullptr, log);
        std::cerr << "Shader error: " << log << std::endl;
        return 0;
    }
    return shader;
}

// Create program
GLuint createProgram(const std::string& vertexSrc, const std::string& fragmentSrc) {
    GLuint vs = compileShader(GL_VERTEX_SHADER, vertexSrc);
    GLuint fs = compileShader(GL_FRAGMENT_SHADER, fragmentSrc);
    if (!vs || !fs) return 0;

    GLuint program = glCreateProgram();
    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);
    GLint status;
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (!status) {
        char log[512];
        glGetProgramInfoLog(program, 512, nullptr, log);
        std::cerr << "Program error: " << log << std::endl;
        return 0;
    }
    glDeleteShader(vs);
    glDeleteShader(fs);
    return program;
}

// Mouse data struct
struct MouseData {
    double mouseX = 0.0;
    double mouseY = 0.0;
    double clickX = 0.0;
    double clickY = 0.0;
};

// Static callbacks
static void cursorPosCallback(GLFWwindow* win, double x, double y) {
    MouseData* data = static_cast<MouseData*>(glfwGetWindowUserPointer(win));
    data->mouseX = x;
    data->mouseY = y;
}

static void mouseButtonCallback(GLFWwindow* win, int button, int action, int mods) {
    MouseData* data = static_cast<MouseData*>(glfwGetWindowUserPointer(win));
    if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
        data->clickX = data->mouseX;
        data->clickY = data->mouseY;
    }
}

int main() {
    // Initialize GLFW
    if (!glfwInit()) {
        std::cerr << "GLFW init failed" << std::endl;
        return -1;
    }

    // Window hints for OpenGL 4.1 (macOS compatible)
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

    GLFWwindow* window = glfwCreateWindow(800, 600, "GLSL Renderer", nullptr, nullptr);
    if (!window) {
        std::cerr << "Window creation failed" << std::endl;
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    glewExperimental = GL_TRUE;
    if (glewInit() != GLEW_OK) {
        std::cerr << "GLEW init failed" << std::endl;
        return -1;
    }

    // Quad vertices
    float vertices[] = {
        -1.0f, -1.0f,  1.0f, -1.0f,  -1.0f, 1.0f,
         1.0f, -1.0f,  1.0f, 1.0f,   -1.0f, 1.0f
    };

    GLuint vao, vbo;
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, nullptr);
    glEnableVertexAttribArray(0);

    // Load initial shaders
    std::filesystem::path exeDir = std::filesystem::path(__FILE__).parent_path();
    std::string vertexPath = (exeDir / "vertex.glsl").string();
    std::string fragmentPath = (exeDir / "fragment.glsl").string();

    std::string vertexSrc = readFile(vertexPath);
    std::string fragmentSrc = readFile(fragmentPath);
    std::string lastFragmentSrc = fragmentSrc;

    GLuint program = createProgram(vertexSrc, fragmentSrc);
    if (!program) return -1;

    // Uniform locations
    GLint timeLoc = glGetUniformLocation(program, "iTime");
    GLint resLoc = glGetUniformLocation(program, "iResolution");
    GLint mouseLoc = glGetUniformLocation(program, "iMouse");

    // Mouse tracking setup
    MouseData mouseData;
    glfwSetWindowUserPointer(window, &mouseData);
    glfwSetCursorPosCallback(window, cursorPosCallback);
    glfwSetMouseButtonCallback(window, mouseButtonCallback);

    auto start = std::chrono::steady_clock::now();

    while (!glfwWindowShouldClose(window)) {
        // Poll for file changes (every 500ms; improve with inotify/epoll later)
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        fragmentSrc = readFile(fragmentPath);
        if (fragmentSrc != lastFragmentSrc && !fragmentSrc.empty()) {
            lastFragmentSrc = fragmentSrc;
            GLuint newProgram = createProgram(vertexSrc, fragmentSrc);
            if (newProgram) {
                glDeleteProgram(program);
                program = newProgram;
                timeLoc = glGetUniformLocation(program, "iTime");
                resLoc = glGetUniformLocation(program, "iResolution");
                mouseLoc = glGetUniformLocation(program, "iMouse");
            }
        }

        // Render
        int width, height;
        glfwGetFramebufferSize(window, &width, &height);
        glViewport(0, 0, width, height);

        auto now = std::chrono::steady_clock::now();
        float time = std::chrono::duration<float>(now - start).count();

        glUseProgram(program);
        glUniform1f(timeLoc, time);
        glUniform2f(resLoc, static_cast<float>(width), static_cast<float>(height));
        glUniform4f(mouseLoc, static_cast<float>(mouseData.mouseX), static_cast<float>(height - mouseData.mouseY),
                    static_cast<float>(mouseData.clickX), static_cast<float>(height - mouseData.clickY));

        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        glBindVertexArray(vao);
        glDrawArrays(GL_TRIANGLES, 0, 6);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    // Cleanup
    glDeleteVertexArrays(1, &vao);
    glDeleteBuffers(1, &vbo);
    glDeleteProgram(program);
    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}