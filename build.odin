package main

import "core:os/os2"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:time"

run_cmd :: proc (cmd: []string) {
    str := strings.join(cmd, " ")
    fmt.printfln("INFO: Running command '%s'", str)
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

be_annoying :: proc (cmd: ^[dynamic]string) {
    append(cmd, "-strict-style")
    append(cmd, "-vet-using-stmt")
    append(cmd, "-vet-using-param")
    append(cmd, "-vet-unused")
    append(cmd, "-vet-shadowing")
    append(cmd, "-vet-cast")
}

main :: proc () {
    prepare()

    cmd: [dynamic]string
    append(&cmd, "odin")
    append(&cmd, "build")
    append(&cmd, "src")
    append(&cmd, "-out:build/lenia")
    append(&cmd, "-o:speed")
    append(&cmd, "-error-pos-style:unix")
    append(&cmd, "-sanitize:address")
    be_annoying(&cmd)
    thread_count_str := fmt.aprintf("-thread-count:%d", os.processor_core_count())
    append(&cmd, thread_count_str)

    run_cmd(cmd[:])
}
