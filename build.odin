package main

import "core:os/os2"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:time"

Command :: distinct [dynamic]string

run_cmd :: proc (cmd: ^Command) {
    str := strings.join(cmd[:], " ")
    fmt.printfln("COMMAND: '%s'", str)
    delete(str)

    handle, _ := os2.process_start({
        command = cmd[:],
        stdin = os2.stdin,
        stdout = os2.stdout,
        stderr = os2.stderr,

    })

    state, _ := os2.process_wait(handle)
    if state.exit_code != 0 {
        os2.exit(state.exit_code)
    }
}

prepare :: proc () {
    if os2.is_file("build") {
        os2.remove("build")
    }
    if os2.is_file("build.bin") {
        os2.remove("build.bin")
    }
    os2.make_directory("build")
}

optimization_flags :: proc (cmd: ^Command) {
    append(cmd, "-o:speed")
}

strict_style_flags :: proc (cmd: ^Command) {
    append(cmd, "-strict-style")
    append(cmd, "-vet-using-stmt")
    append(cmd, "-vet-using-param")
    append(cmd, "-vet-unused")
    append(cmd, "-vet-shadowing")
    append(cmd, "-vet-cast")
}

make_build_cmd :: proc (pkg, out: string) -> Command {
    cmd: Command
    append(&cmd, "odin")
    append(&cmd, "build")
    append(&cmd, pkg)
    out_str := fmt.aprintf("-out:%s", out)
    append(&cmd, out_str)

    return cmd
}

main :: proc () {
    prepare()

    cmd := make_build_cmd("src", "build/lenia")
    append(&cmd, "-error-pos-style:unix")
    strict_style_flags(&cmd)
    // optimization_flags(&cmd)

    run_cmd(&cmd)
}
