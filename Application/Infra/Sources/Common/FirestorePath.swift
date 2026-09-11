//
//  FirestorePath.swift
//  Infra
//
//  Created by opfic on 3/26/26.
//

enum FirestorePath {
    private enum Collection: String {
        case users
        case userData
        case counters
        case todoLists
        case developmentGoals
        case records
        case versions
        case notifications
    }

    enum UserData: String {
        case info
        case tokens
        case settings
        case categories
    }

    enum Counter: String {
        case todo
    }

    static func user(_ uid: String) -> String {
        "\(Collection.users.rawValue)/\(uid)"
    }

    static func userData(_ uid: String, document: UserData? = nil) -> String {
        let path = "\(user(uid))/\(Collection.userData.rawValue)"
        guard let document else { return path }
        return "\(path)/\(document.rawValue)"
    }

    static func counter(_ uid: String, document: Counter) -> String {
        "\(user(uid))/\(Collection.counters.rawValue)/\(document.rawValue)"
    }

    static func todos(_ uid: String) -> String {
        "\(user(uid))/\(Collection.todoLists.rawValue)"
    }

    static func todo(_ uid: String, todoId: String) -> String {
        "\(todos(uid))/\(todoId)"
    }

    static func developmentGoals(_ uid: String) -> String {
        "\(user(uid))/\(Collection.developmentGoals.rawValue)"
    }

    static func developmentGoal(_ uid: String, goalId: String) -> String {
        "\(developmentGoals(uid))/\(goalId)"
    }

    static func developmentRecords(_ uid: String, goalId: String) -> String {
        "\(developmentGoal(uid, goalId: goalId))/\(Collection.records.rawValue)"
    }

    static func developmentRecord(
        _ uid: String,
        goalId: String,
        recordId: String
    ) -> String {
        "\(developmentRecords(uid, goalId: goalId))/\(recordId)"
    }

    static func developmentRecordVersions(
        _ uid: String,
        goalId: String,
        recordId: String
    ) -> String {
        "\(developmentRecord(uid, goalId: goalId, recordId: recordId))/\(Collection.versions.rawValue)"
    }

    static func developmentRecordVersion(
        _ uid: String,
        goalId: String,
        recordId: String,
        versionId: String
    ) -> String {
        "\(developmentRecordVersions(uid, goalId: goalId, recordId: recordId))/\(versionId)"
    }

    static func notifications(_ uid: String) -> String {
        "\(user(uid))/\(Collection.notifications.rawValue)"
    }

}
